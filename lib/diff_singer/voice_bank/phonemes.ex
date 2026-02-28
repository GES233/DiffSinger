defmodule DiffSinger.VoiceBank.Phonemes do
  alias DiffSinger.VoiceBank

  def get_phonemes_dict(%VoiceBank{root_conf: conf, root_path: path}) do
    lang_dict = case conf["use_lang_id"] do
      nil -> nil
      true -> conf["languages"]
    end

    phoneme_dict = case Path.extname(conf["phonemes"]) do
      ".json" ->
        Path.join(path, conf["phonemes"])
        |> File.read!()
        |> Jason.decode!()

      ".txt" ->
        dicts = Path.join(path, conf["phonemes"])
        |> File.read!()
        |> String.split(["\n", "\r\n"])
        |> Enum.reject(& &1 == "")

        dicts
        |> Enum.zip(Range.new(0, length(dicts)))
        |> Enum.into(%{})
    end

    {lang_dict, phoneme_dict}
  end
end
