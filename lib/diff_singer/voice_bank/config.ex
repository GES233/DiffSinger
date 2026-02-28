defmodule DiffSinger.VoiceBank.Config do
  alias DiffSinger.VoiceBank
  alias DiffSinger.VoiceBank.{Vocoder, Acoustic, Linguistic, Duration, Pitch, Variance, Phonemes}

  defstruct [:acoustic, :vocoder, :predict_map, :variance]

  def fetch_overview(root_path) do
    base = VoiceBank.load(root_path)

    acoustic = Acoustic.get_acoustic_model(base)

    maybe_pitch_linguistic = Linguistic.get_linguistic_for_pitch(base)

    pitch_phonemes =
      if maybe_pitch_linguistic.usable do
        Phonemes.maybe_get_phonemes_dict_for_pitch(maybe_pitch_linguistic, root_path)
      else
        nil
      end

    maybe_duration_linguistic = Linguistic.get_linguistic_for_duration(base)

    duration_phonemes =
      if maybe_duration_linguistic.usable do
        Phonemes.maybe_get_phonemes_dict_for_duration(maybe_duration_linguistic, root_path)
      else
        nil
      end

    variance_linguistic = Linguistic.get_linguistic_for_variance(base)

    %__MODULE__{
      vocoder: Vocoder.get_vocoder(base),
      acoustic: %{
        infer: acoustic,
        phonemes: Phonemes.get_phonemes_dict_for_acoustic(acoustic, root_path)
      },
      predict_map: %{
        maybe_pitch: %{
          linguistic: maybe_pitch_linguistic,
          predict: Pitch.get_pitch(base),
          phonemes: pitch_phonemes
        },
        maybe_duration: %{
          linguistic: maybe_duration_linguistic,
          duration: Duration.get_duration(base),
          phonemes: duration_phonemes
        }
      },
      variance: %{
        linguistic: variance_linguistic,
        variance: Variance.get_variance(base),
        phonemes: Phonemes.get_phonemes_dict_for_variance(variance_linguistic, root_path)
      }
    }
  end

  # Acoustic Model
  def get_acoustic_model(%{acoustic: acoustic}) do
    %{infer: %VoiceBank.Model{signature: _signature}} = acoustic

    # Core conditions

    # Diffusion Parameters

    # Others
  end

  # Vocoder
end
