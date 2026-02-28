defmodule DiffSinger.ONNXResolver do
  @moduledoc """
  用于解析 Ortex 模型签名的工具模块。
  将底层的 Rust NIF 返回值清洗为结构化的 Elixir 数据，
  以便为 Orchid 提供构建 DAG 的依据。
  """

  defstruct [:inputs, :outputs]

  @type tensor_info :: %{
          type: Nx.Type.t() | :unknown,
          shape: [integer()] | :unknown
        }

  @type signature :: %__MODULE__{
          inputs: %{String.t() => tensor_info()},
          outputs: %{String.t() => tensor_info()}
        }

  @doc """
  解析 Ortex Model，返回标准化的模型签名。

  ## 示例
      model = Ortex.load("acostic.onnx")
      signature = DiffSinger.ONNX.Resolver.resolve(model)

      # signature.inputs["tokens"].type  => {:s, 64}
      # signature.inputs["tokens"].shape => [1, -1]
  """
  @spec resolve(%Ortex.Model{}) :: signature()
  def resolve(%Ortex.Model{reference: ref}) do
    {raw_inputs, raw_outputs} = Ortex.Native.show_session(ref)

    %__MODULE__{
      inputs: parse_nodes(raw_inputs),
      outputs: parse_nodes(raw_outputs)
    }
  end

  # --- 私有清洗逻辑 ---

  defp parse_nodes(nodes) do
    Map.new(nodes, fn {name, raw_type_str, dims} ->
      {name,
       %{
         type: extract_nx_type(raw_type_str),
         # Rust 返回的 Option<Vec<i64>>，None 会映射为 nil
         shape: dims || :unknown
       }}
    end)
  end

  # 使用正则从 Rust 的 Debug 格式中提取类型，并映射为 Nx Type
  # 匹配目标: "ty: Float32,"
  defp extract_nx_type(raw_str) do
    case Regex.run(~r/ty:\s*([A-Za-z0-9]+)/, raw_str) do
      # ort src/value/impl_tensor/element.rs
      [_, "Float16"] -> {:f, 16}
      [_, "Float32"] -> {:f, 32}
      [_, "Float64"] -> {:f, 64}
      [_, "BFloat16"] -> {:bf, 16}
      [_, "Int64"] -> {:s, 64}
      [_, "Int32"] -> {:s, 32}
      [_, "Int16"] -> {:s, 16}
      [_, "Int8"] -> {:s, 8}
      [_, "Uint8"] -> {:u, 8}
      [_, "Bool"] -> {:u, 8}
      [_, "Uint16"] -> {:u, 16}
      [_, "Uint32"] -> {:u, 32}
      [_, "Uint64"] -> {:u, 64}
      [_, "Float8E4M3FN"] -> {:f8_e4m3fn, 8}
      [_, "Complex64"] -> {:c, 64}
      [_, "Complex128"] -> {:c, 128}
      _ -> :unknown
    end
  end
end
