defmodule DiffSinger.VoiceBank.Duration do
  alias DiffSinger.VoiceBank

  # enable when predict_dur: ture
  def get_duration(%VoiceBank{root_path: path, model: model}) do
    case model["dsdur"] do
      nil ->
        %VoiceBank.Model{
          id: :duration_predict,
          usable: false
        }

      _ ->
        duration_conf =
          Path.wildcard(path <> "/*dur*/*config.{yaml,yml}")
          |> VoiceBank.read_yaml()

        [{linguistic_path, signature}] =
          model["dsdur"]
          |> Enum.filter(fn {k, _} -> duration_conf["dur"] in k end)

        %VoiceBank.Model{
          id: :duration_predict,
          path: linguistic_path,
          signature: signature,
          maybe_config: duration_conf
        }
    end
  end
end
