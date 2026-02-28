defmodule DiffSinger.VoiceBank.Vocoder do
  alias DiffSinger.VoiceBank

  def get_vocoder(%VoiceBank{root_conf: conf, root_path: path, model: model}) do
    vocoder_conf =
      Path.wildcard(path <> "/*vocoder*/**.{yaml,yml}")
      |> VoiceBank.read_yaml()

    model["dsvocoder"]
    |> Enum.filter(fn {k, _} -> vocoder_conf["model"] in k end)
    |> case do
      [{vocoder_path, signature}] ->
        {signature, vocoder_conf}

        %VoiceBank.Model{
          id: :vocoder,
          path: vocoder_path,
          signature: signature,
          maybe_config: vocoder_conf
        }

      [] ->
        # Fallback to conf["vocoder"]
        %VoiceBank.Model{
          id: :vocoder,
          path: conf["vocoder"],
          usable: false
        }
    end
  end
end
