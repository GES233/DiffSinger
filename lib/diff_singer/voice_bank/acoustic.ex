defmodule DiffSinger.VoiceBank.Acoustic do
  alias DiffSinger.VoiceBank

  def get_acoustic_model(%VoiceBank{root_conf: conf, root_path: _path, model: model}) do
    acoustic_model_path = conf["acoustic"]

    [{_acoustic_path, signature}] = model["root"]
    |> Enum.filter(fn {k, _} ->acoustic_model_path in k end)

    {signature, conf}
  end
end
