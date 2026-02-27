defmodule DiffSinger.Pipeline.OpenUTAULibExtractor do
  def load_root_dsconfig(%Orchid.Param{payload: root_path}, _step_options) do
    root_dsconfig =
      [root_path, "dsconfig.{yaml,yml}"]
      |> Path.join()
      |> Path.wildcard()
      |> Enum.map(&:yamerl.decode_file/1)

    {:ok, Orchid.Param.new(:root_dsconfig, :dsconfig, root_dsconfig)}
  end

  def load_acostic_model([%Orchid.Param{payload: _root_path}, %Orchid.Param{payload: _root_dsconfig}], _step_options) do
    # get acostic value
    # merge path
    {:ok, Orchid.Param.new(:acostic_model, DiffSinger.Worker.OrtexRunner)}
  end

  defmodule VocoderConfig do
    # ...
  end
end
