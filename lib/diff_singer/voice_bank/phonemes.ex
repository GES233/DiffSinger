defmodule DiffSinger.VoiceBank.Phonemes do
  alias DiffSinger.VoiceBank

  def get_phonemes_dict_for_acoustic(%VoiceBank.Model{maybe_config: conf}, root_path) do
    get_phonemes(conf, root_path)
  end

  def maybe_get_phonemes_dict_for_pitch(%VoiceBank.Model{maybe_config: conf}, root_path) do
    get_phonemes(conf, Path.join(root_path, "dspitch"))
  end

  def maybe_get_phonemes_dict_for_duration(%VoiceBank.Model{maybe_config: conf}, root_path) do
    get_phonemes(conf, Path.join(root_path, "dsdur"))
  end

  def get_phonemes_dict_for_variance(%VoiceBank.Model{maybe_config: conf}, root_path) do
    get_phonemes(conf, Path.join(root_path, "dsvariance"))
  end

  defp get_phonemes(conf, path) do
    lang_dict =
      with true <- conf["use_lang_id"], ".json" <- Path.extname(conf["languages"]) do
        Path.join(path, conf["languages"])
        |> File.read!()
        |> Jason.decode!()
      else
        nil -> nil
      end

    phoneme_dict =
      case Path.extname(conf["phonemes"]) do
        ".json" ->
          Path.join(path, conf["phonemes"])
          |> File.read!()
          |> Jason.decode!()

        ".txt" ->
          dicts =
            Path.join(path, conf["phonemes"])
            |> File.read!()
            |> String.split(["\n", "\r\n"])
            |> Enum.reject(&(&1 == ""))

          dicts
          |> Enum.zip(Range.new(0, length(dicts)))
          |> Enum.into(%{})
      end

    %{maybe_lang_dict: lang_dict, phoneme_dict: phoneme_dict}
  end
end
