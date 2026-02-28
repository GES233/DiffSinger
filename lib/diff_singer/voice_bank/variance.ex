defmodule DiffSinger.VoiceBank.Variance do
  alias DiffSinger.VoiceBank

  def get_variance(%VoiceBank{root_path: path, model: model}) do
    variance_conf =
      Path.wildcard(path <> "/*variance*/**.{yaml,yml}")
      |> VoiceBank.read_yaml()

    [{_variance_path, _signature}] =
      model["dsvariance"]
      |> Enum.filter(fn {k, _} -> variance_conf["variance"] in k end)
  end
end
