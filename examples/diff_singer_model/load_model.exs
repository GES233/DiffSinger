defmodule Qixuan_V2_5_0 do
  @doc """
  Model info.
  """
  @meta %{
    name: "绮萱",
    version: "v2.5.0",
    author: "DiffSinger Community",
    author_link: "https://github.com/openvpi/DiffSinger"
  }

  def import_meta(), do: @meta |> IO.inspect(); nil
end

## Temporary
model_root_path = "E:/ProgramAssets/OpenUTAUSingers/Qixuan_v2.5.0_DiffSinger_OpenUtau"
model_path = fn sub -> Path.join(model_root_path, sub) end
# Variance Model
# pitch_predict_path = model_path.("")
_linguisitic_path = model_path.("dsvariance/0816_qixuan_multilingual_multivar.qixuan.linguistic.onnx")
_variance_path = model_path.("dsvariance/0816_qixuan_multilingual_multivar.qixuan.variance.onnx")
# Acostic Model
acoustic_model_path = model_path.("0816_qixuan_multilingual_acoustic.qixuan.onnx")
# Vocoder
vocoder_path = model_path.("dsvocoder/nsf_hifigan_qixuan_004.onnx")

Ortex.load(acoustic_model_path, [:cpu], 1) |> DiffSinger.ONNXResolver.resolve() |> IO.inspect()

DiffSinger.POC.run_pipeline(acoustic_model_path, vocoder_path)
