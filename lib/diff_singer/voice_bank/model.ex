defmodule DiffSinger.VoiceBank.Model do
  @type t :: %__MODULE__{
    id: atom() | String.t(),
    path: [binary()],
    signature: DiffSinger.ONNXResolver.signature(),
    maybe_config: map(),
    usable: boolean()
  }
  defstruct [:id, :path, :signature, :maybe_config, usable: true]

  def to_path(root, %__MODULE__{path: path_partial}), do: Path.join(root ++ List.wrap(path_partial))
end
