defmodule Orchid.Symbiont.OrtexRunner do
  use GenServer
  require Logger

  def start_link(arg) do
    {name, final_opts} = Keyword.pop(arg, :name)

    Supervisor.start_link(__MODULE__, final_opts, name: name)
  end

  @impl true
  def init(opts) do
    model_path = Keyword.fetch!(opts, :path)
    providers = Keyword.get(opts, :providers, [:cpu])
    optimization_level = Keyword.get(opts, :optimization_level, 1)

    if optimization_level >= 2 do
      Logger.warning("`optimization_level` too high may cause BEAM crash slicently.")
    end

    try do
      Ortex.load(model_path, providers, optimization_level)
    rescue
      e -> {:error, e}
    else
      model = %Ortex.Model{} ->
        # use model session
        signature = DiffSinger.ONNXResolver.resolve(model)

        # merge config
        # ...

        {:ok,
         %{
           model: model,
           model_path: model_path,
           providers: providers,
           optimization_level: optimization_level,
           signature: {signature.inputs, signature.outputs}
         }}
    end
  end

  @impl true
  def handle_call({:infer, inputs_tuple}, _from, %{model: model, providers: providers} = state) do
    {elapse, result} = :timer.tc(fn -> Ortex.run(model, inputs_tuple) end)

    Logger.debug("[Symbiont] Inference took #{elapse / 1000}ms via provider #{inspect(providers)}")

    {:reply, {:ok, result}, state}
  end

  @impl true
  def handle_call({:infer_with_ref, inputs_tuple}, _from, %{model: model} = state) do
    {_elapse, result} = :timer.tc(fn -> Ortex.run(model, inputs_tuple) end)

    {:reply, {:ok, result}, state}
  end

  def handle_call({:get_signature}, _from, %{signature: signature} = state) do
    {:reply, {:ok, signature}, state}
  end

  @impl true
  def handle_info(:timeout, state) do
    Logger.info("[Symbiont] 模型 #{state.model_path} 闲置超时，正在卸载并释放显存...")

    {:stop, :normal, state}
  end

  # load_from_ref
end
