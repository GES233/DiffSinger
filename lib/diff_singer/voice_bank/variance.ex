defmodule DiffSinger.VoiceBank.Variance do
  alias DiffSinger.VoiceBank

  def get_variance(%VoiceBank{root_path: path, model: model}) do
    variance_conf =
      Path.wildcard(path <> "/*variance*/*config.{yaml,yml}")
      |> VoiceBank.read_yaml()

    [{variance_path, signature}] =
      model["dsvariance"]
      |> Enum.filter(fn {k, _} -> variance_conf["variance"] in k end)

    %VoiceBank.Model{
      id: :variance_model,
      path: variance_path,
      signature: signature,
      maybe_config: variance_conf
    }
  end
end
