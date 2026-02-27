defmodule DiffSinger.Worker.OrtexRunner do
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
      Logger.warning("`optimization_level` too high may cause BEAM slicently crash.")
    end

    try do
      Ortex.load(model_path, providers, optimization_level)
    rescue
      e -> {:error, e}
    else
      model = %Ortex.Model{} ->
        # merge config
        {:ok,
         %{
           model: model,
           model_path: model_path,
           providers: providers,
           optimization_level: optimization_level
         }}
    end
  end

  @impl true
  def handle_call({:infer, inputs_tuple}, _from, %{model: model, providers: providers} = state) do
    {elapse, result} = :timer.tc(fn -> Ortex.run(model, inputs_tuple) end)

    Logger.debug("[Symbiont] Inference took #{elapse / 1000}ms via provider #{inspect(providers)}")

    {:reply, {:ok, result}, state}
  end
end
