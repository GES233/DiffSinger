defmodule DiffSinger.Pipeline.OpenUTAULibExtractor do
  def load_root_dsconfig(%Orchid.Param{payload: root_path}, _step_options) do
    root_dsconfig =
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
      |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
      |> Enum.into(%{})

    {:ok, Orchid.Param.new(:root_dsconfig, :dsconfig, root_dsconfig)}
  end

  def load_acoustic_model(
        [%Orchid.Param{payload: root_path}, %Orchid.Param{payload: root_dsconfig}],
        _step_options
      ) do
    with acoustic_path = Path.join(root_path, root_dsconfig.acoustic),
         true <- File.exists?(acoustic_path) do
      # TODO: write opts
      {:ok, Orchid.Param.new(:acoustic_path, DiffSinger.Worker.OrtexRunner, [])}
    else
      false -> {:error, {:file_not_exist, :acoustic_path}}
    end
  end

  def phonemes_dictionary_loader(
        [%Orchid.Param{payload: root_path}, %Orchid.Param{payload: root_dsconfig}],
        _step_options
      ) do
    with phonemes_path = Path.join(root_path, root_dsconfig.phonemes),
         true <- File.exists?(phonemes_path) do
      case Path.extname(phonemes_path) do
        "json" ->
          # ...
          nil

        "txt" ->
          # ...
          nil
      end
    else
      false -> {:error, {:file_not_exist, :phonemes_path}}
    end
  end

  def load_vocoder(
        [%Orchid.Param{payload: _root_path}, %Orchid.Param{payload: _root_dsconfig}],
        _step_options
      ) do
    # ...
  end
end
