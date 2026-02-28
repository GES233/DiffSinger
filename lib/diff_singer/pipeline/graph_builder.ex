defmodule DiffSinger.Pipeline.GraphBuilder do
  @moduledoc """
  解析 ONNX，动态注册 Symbiont 蓝图，并构建纯数据 DAG。
  """
  alias Lily.Graph
  alias Lily.Graph.{Node, Edge}
  alias DiffSinger.ONNXResolver

  @spec build_graph(binary(), binary()) :: {:ok, Graph.t()} | {:error, term()}
  def build_graph(acoustic_path, vocoder_path) do
    # 抽取签名
    {:ok, acoustic_sig} = resolve_model(acoustic_path)
    {:ok, vocoder_sig} = resolve_model(vocoder_path)

    # 1. 为模型生成全局唯一的 Symbiont ID
    ac_symbiont_ref = generate_symbiont_ref(acoustic_path)
    vo_symbiont_ref = generate_symbiont_ref(vocoder_path)

    # 2. 注册惰性求值蓝图 (不会立即启动，直到 Step 运行)
    Orchid.Symbiont.register(
      ac_symbiont_ref,
      {Orchid.Symbiont.OrtexRunner, path: acoustic_path, providers: [:cpu]}
    )

    Orchid.Symbiont.register(
      vo_symbiont_ref,
      {Orchid.Symbiont.OrtexRunner, path: vocoder_path, providers: [:cpu]}
    )

    # 3. 构建节点图
    # 4. 自动连线 (例如: acoustic.mel -> vocoder.mel)
    # ... (复用之前的连线逻辑)
    {:ok,
     %Graph{}
     |> Graph.add_node(build_node(:acoustic, acoustic_sig, ac_symbiont_ref))
     |> Graph.add_node(build_node(:vocoder, vocoder_sig, vo_symbiont_ref))
     |> auto_wire(:acoustic, acoustic_sig, :vocoder, vocoder_sig)}
  end

  defp build_node(node_id, sig, symbiont_ref) do
    %Node{
      id: node_id,
      impl: DiffSinger.Step.OrtexSymbiontStep,
      inputs: Map.keys(sig.inputs) |> Enum.map(&String.to_atom/1),
      outputs: Map.keys(sig.outputs) |> Enum.map(&String.to_atom/1),
      opts: [
        symbiont_ref: symbiont_ref,
        signature: sig,
        extra_hooks_stack: [Orchid.Symbiont.Hooks.Injector]
      ]
    }
  end

  defp generate_symbiont_ref(path) do
    hash = :crypto.hash(:md5, path) |> Base.encode16(case: :lower)
    :"model_#{binary_part(hash, 0, 8)}"
  end

  defp resolve_model(model_path) do
    # 这里我们使用 Task 隔离 Ortex NIF 调用，防止偶发的段错误影响主进程
    Task.async(fn ->
      try do
        # 仅读取签名时，可以用最保守的 CPU + O0 模式
        model = Ortex.load(model_path, [:cpu], 0)
        signature = ONNXResolver.resolve(model)
        {:ok, signature}
      rescue
        e -> {:error, e}
      end
    end)
    |> Task.await(:infinity)
  end

  defp auto_wire(graph, n1, sig1, n2, sig2),
    do: Graph.add_edge(graph, Edge.new(n1, sig1, n2, sig2))
end
