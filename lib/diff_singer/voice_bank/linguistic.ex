defmodule DiffSinger.VoiceBank.Linguistic do
  alias DiffSinger.VoiceBank

  def get_linguistic_for_variance(%VoiceBank{root_path: path, model: model}) do
    linguistic_conf =
      Path.wildcard(path <> "/*variance*/*config.{yaml,yml}")
      |> VoiceBank.read_yaml()

    [{linguistic_path, signature}] =
      model["dsvariance"]
      |> Enum.filter(fn {k, _} -> linguistic_conf["linguistic"] in k end)

    %VoiceBank.Model{
      id: :linguistic_for_variance,
      path: linguistic_path,
      signature: signature,
      maybe_config: linguistic_conf
    }
  end

  def get_linguistic_for_duration(%VoiceBank{root_path: path, model: model}) do
    case model["dsdur"] do
      nil ->
        %VoiceBank.Model{
          id: :linguistic_for_duration,
          usable: false
        }

      _ ->
        linguistic_conf =
          Path.wildcard(path <> "/*dur*/*config.{yaml,yml}")
          |> VoiceBank.read_yaml()

        [{linguistic_path, signature}] =
          model["dsdur"]
          |> Enum.filter(fn {k, _} -> linguistic_conf["linguistic"] in k end)

        %VoiceBank.Model{
          id: :linguistic_for_duration,
          path: linguistic_path,
          signature: signature,
          maybe_config: linguistic_conf
        }
    end
  end

  def get_linguistic_for_pitch(%VoiceBank{root_path: path, model: model}) do
    case model["dspitch"] do
      nil ->
        %VoiceBank.Model{
          id: :linguistic_for_pitch,
          usable: false
        }

      _ ->
        linguistic_conf =
          Path.wildcard(path <> "/*pitch*/*config.{yaml,yml}")
          |> VoiceBank.read_yaml()

        [{linguistic_path, signature}] =
          model["dspitch"]
          |> Enum.filter(fn {k, _} -> linguistic_conf["linguistic"] in k end)

        %VoiceBank.Model{
          id: :linguistic_for_pitch,
          path: linguistic_path,
          signature: signature,
          maybe_config: linguistic_conf
        }
    end
  end
end
