defmodule DiffSinger.VoiceBank.Pitch do
  alias DiffSinger.VoiceBank

  # enable when predict_dur: true
  def get_pitch(%VoiceBank{root_path: path, model: model}) do
    case model["dspitch"] do
      nil ->
        %VoiceBank.Model{
          id: :pitch_predict,
          usable: false
        }

      _ ->
        duration_conf =
          Path.wildcard(path <> "/*pitch*/*config.{yaml,yml}")
          |> VoiceBank.read_yaml()

        [{linguistic_path, signature}] =
          model["dspitch"]
          |> Enum.filter(fn {k, _} -> duration_conf["pitch"] in k end)

        %VoiceBank.Model{
          id: :pitch_predict,
          path: linguistic_path,
          signature: signature,
          maybe_config: duration_conf
        }
    end
  end
end
