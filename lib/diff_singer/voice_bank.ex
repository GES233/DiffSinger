defmodule DiffSinger.VoiceBank do
  defstruct [:root_path, :model, :char_conf, :root_conf]

  def load(root_path) do
    root_conf =
      [root_path, "dsconfig.{yaml,yml}"]
      |> Path.join()
      |> read_yaml()

    char_conf =
      [root_path, "dschar*.{yaml,yml}"]
      |> Path.join()
      |> read_yaml()

    model = get_all_models(root_path)

    %__MODULE__{root_path: root_path, model: model, char_conf: char_conf, root_conf: root_conf}
  end

  defp read_yaml(pattern) do
    pattern
    |> Path.wildcard()
    |> Enum.map(&YamlElixir.read_all_from_file!/1)
    |> List.flatten()
    |> case do
      [res] -> res
      _ = multi -> Enum.reduce(multi, &Map.merge/2)
    end
    |> Enum.uniq()
    |> Enum.into(%{})
  end

  def model_helper(model_path) do
    Task.async(fn ->
      model = Ortex.load(model_path, [:cpu], 1)

      signature = DiffSinger.ONNXResolver.resolve(model)

      signature
    end)
    |> Task.await(:infinity)
  end

  def get_all_models(root_path) do
    (root_path <> "/**/*.onnx")
    |> Path.wildcard()
    |> Enum.map(fn p -> {Path.relative_to(p, root_path) |> Path.split(), model_helper(p)} end)
  end
end
