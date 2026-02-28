defmodule DiffSinger.Pipeline.OpenUTAULibExtractor do
  def load_root_dsconfig(root_path) do
      [root_path, "dsconfig.{yaml,yml}"]
      |> Path.join()
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

  def load_acoustic_model(root_path, root_dsconfig) do
    with acoustic_path = Path.join(root_path, root_dsconfig["acoustic"]),
         true <- File.exists?(acoustic_path) do
      # TODO: write opts
    else
      false -> {:error, {:file_not_exist, :acoustic_path}}
    end
  end

  def phonemes_dictionary_loader(root_path, root_dsconfig) do
    with phonemes_path = Path.join(root_path, root_dsconfig["phonemes"]),
    languages_path = Path.join(root_path, root_dsconfig["languages"]),
         {true, _phonemes_exist} <- {File.exists?(phonemes_path), File.exists?(languages_path)} do
      case Path.extname(phonemes_path) do
        "json" ->
          # ...
          nil

        "txt" ->
          # ...
          nil
      end
    else
      {false, _} -> {:error, {:file_not_exist, :phonemes_path}}
    end
  end

  # MUST USE Serial Executor
  @spec model_helper(binary()) :: DiffSinger.ONNXResolver.signature()
  def model_helper(model_path) do
    Task.async(fn ->
      model = Ortex.load(model_path, [:cpu], 1)

      signature = DiffSinger.ONNXResolver.resolve(model)

      signature
    end) |> Task.await(:infinity)
  end

  def get_all_models(root_path) do
    root_path <> "/**/*.onnx"
    |> Path.wildcard()
    |> Enum.map(fn p -> {Path.relative_to(p, root_path) |> Path.split(), model_helper(p)} end)
  end
end
