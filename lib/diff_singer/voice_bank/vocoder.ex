defmodule DiffSinger.VoiceBank.Vocoder do
  alias DiffSinger.VoiceBank

  def get_vocoder(%VoiceBank{root_conf: _conf, root_path: path, model: model}) do
    vocoder_conf = Path.wildcard(path <> "/*vocoder*/**.{yaml,yml}")
    |> VoiceBank.read_yaml()

      model["dsvocoder"]
      |> Enum.filter(fn {k, _} -> vocoder_conf["model"] in k end)
      |> case do
        [{_acoustic_path, signature}] -> {signature, vocoder_conf}
        [] ->
          # Fallback to conf["vocoder"]
          {nil, nil}
      end
  end
end
