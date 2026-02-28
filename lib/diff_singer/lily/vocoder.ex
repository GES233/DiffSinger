defmodule DiffSinger.Lily.Vocoder do
  alias DiffSinger.VoiceBank.{Model, Config}
  alias Lily.Graph.Node

  def from_config(%Config{vocoder: %Model{signature: _signature, usable: true}}) do

    %Node{
      id: :vocoder
    }
  end
end
