defmodule DiffSinger.VoiceBank.Acoustic do
  alias DiffSinger.VoiceBank

  def get_acoustic_model(%VoiceBank{root_conf: conf, root_path: _path, model: model}) do
    acoustic_model_path = conf["acoustic"]

    [{acoustic_path, signature}] =
      model["root"]
      |> Enum.filter(fn {k, _} -> acoustic_model_path in k end)

    %VoiceBank.Model{
      id: :acoustic_model,
      path: acoustic_path,
      signature: signature,
      maybe_config: conf
    }
  end
end
