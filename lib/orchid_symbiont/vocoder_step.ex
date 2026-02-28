defmodule OrchidSymbiont.VocoderStep do
  @behaviour Orchid.Symbiont.Step

  def required, do: [:vocoder]

  def run_with_model(_inputs, symbiont_map, _opts) do
    _vocoder = symbiont_map.vocoder
    {:ok, nil}
  end
end
