defmodule DiffSinger.POC do
  @moduledoc """
  手动构造张量，跑通 DiffSinger 声学模型推理的最简验证。
  """
  require Logger
  alias Orchid.Symbiont.OrtexRunner

  @doc """
  执行测试。传入你的声学模型 (.onnx) 路径。
  """
  def run_acoustic(model_path) do
    # 1. 启动并挂载模型 (这里我们不走 Symbiont，直接手动启一个独立进程方便测试)
    Logger.info("=> 正在加载模型: #{model_path}")
    {:ok, runner_pid} = GenServer.start_link(OrtexRunner, path: model_path, providers: [:cpu])

    # 2. 构造符合物理逻辑的 Dummy Tensors
    inputs_tuple = build_dummy_inputs()

    # 3. 执行推理
    Logger.info("=> 正在执行推理 (Inference)...")

    # 注意：Ortex 要求传入的是一个 Tuple，且顺序必须与 show_session 的输入顺序完全一致！
    case GenServer.call(runner_pid, {:infer, inputs_tuple}, :infinity) do
      {:ok, result_tuple} ->
        # Ortex 返回的也是 Tuple，里面包含输出的 Tensors
        {mel_tensor} = result_tuple

        Logger.info("=> 🎉 推理成功！")
        Logger.info("=> 输出 Mel 频谱 Shape: #{inspect(Nx.shape(mel_tensor))}")
        Logger.info("=> 输出 Mel 频谱 Type: #{inspect(Nx.type(mel_tensor))}")

        # 打印部分数据看看
        IO.inspect(mel_tensor, limit: 5)

        # 验证完毕，关闭模型释放显存
        GenServer.stop(runner_pid)
        :ok

      {:error, reason} ->
        Logger.error("=> ❌ 推理失败: #{inspect(reason)}")
    end
  end

  @doc """
  端到端测试：声学模型 -> 声码器 -> WAV 文件导出
  """
  def run_pipeline(acoustic_path, vocoder_path, output_wav \\ "test.wav") do
    Logger.info("=> 1. 启动模型服务...")
    {:ok, ac_pid} = GenServer.start_link(OrtexRunner, path: acoustic_path, providers: [:cpu])
    {:ok, vo_pid} = GenServer.start_link(OrtexRunner, path: vocoder_path, providers: [:cpu])

    # 构造输入 (60帧，大概对应 0.6 秒多一点的时间)
    inputs_tuple = build_dummy_inputs()
    # 提取 f0 供声码器使用 (假设 f0 是元组的第4个元素，即下标 3)
    f0 = elem(inputs_tuple, 3)

    Logger.info("=> 2. 执行声学模型 (Acoustic) 推理...")
    {:ok, {mel_tensor}} = GenServer.call(ac_pid, {:infer, inputs_tuple}, :infinity)
    Logger.info("   -> 获得 Mel 频谱: #{inspect(Nx.shape(mel_tensor))}")

    # 注意：声码器的输入通常是 {mel, f0}。
    # 你可以先用你的 Resolver 确认一下 Vocoder 的输入签名。通常是先 mel 后 f0。
    vocoder_inputs = {mel_tensor, f0}

    Logger.info("=> 3. 执行声码器 (Vocoder) 推理...")
    {:ok, {audio_tensor}} = GenServer.call(vo_pid, {:infer, vocoder_inputs}, :infinity)

    # 出来的形状应该是 {1, 采样点数量}，比如 {1, 30720}
    Logger.info("   -> 获得音频波形: #{inspect(Nx.shape(audio_tensor))}")

    Logger.info("=> 4. 导出音频文件到 #{output_wav}...")
    save_to_wav(audio_tensor, output_wav, 44100) # Qixuan 通常是 44.1kHz

    # 清理战场
    GenServer.stop(ac_pid)
    GenServer.stop(vo_pid)
    Logger.info("=> 🎉 全流程完成！快去听听 #{output_wav} 吧！(虽然是一声长音)")
  end

  # --- 私有方法：将 Nx 张量写入标准 WAV 文件 ---

  defp save_to_wav(audio_tensor, filename, sample_rate) do
    # 把 Tensor 展平为 1 维，并转换成底层的二进制数据 (Float32, 小端序)
    flat_tensor = Nx.flatten(audio_tensor)
    pcm_data = Nx.to_binary(flat_tensor)

    # 计算一些 WAV 头的必要参数
    byte_rate = sample_rate * 1 * 4  # sample_rate * channels * bytes_per_sample (Float32=4)
    data_size = byte_size(pcm_data)
    file_size = 36 + data_size

    # 构造 44 字节的标准 RIFF/WAVE 文件头 (IEEE Float 格式)
    header = <<
      "RIFF", file_size::little-integer-size(32), "WAVE",
      "fmt ", 16::little-integer-size(32),       # Subchunk1Size (16 for PCM)
      3::little-integer-size(16),                # AudioFormat (3 = IEEE Float)
      1::little-integer-size(16),                # NumChannels (1 = Mono)
      sample_rate::little-integer-size(32),      # SampleRate
      byte_rate::little-integer-size(32),        # ByteRate
      4::little-integer-size(16),                # BlockAlign (channels * bytes_per_sample)
      32::little-integer-size(16),               # BitsPerSample (32 bits)
      "data", data_size::little-integer-size(32) # Subchunk2Size
    >>

    File.write!(filename, header <> pcm_data)
  end

  # --- 私有方法：构造伪造数据 ---

  defp build_dummy_inputs() do
    # 设定：一共 3 个音素，时长分别是 10帧, 20帧, 30帧
    # 注意 DiffSinger 要求 batch_size = 1，所以 shape 都是 [1, 长度]

    # 【音素级输入】 Shape: [1, 3]
    tokens    = Nx.tensor([[10, 24, 30]], type: {:s, 64}) # 假设的音素 ID
    languages = Nx.tensor([[0, 0, 0]], type: {:s, 64})    # 语种 ID (一般全 0)
    durations = Nx.tensor([[10, 20, 30]], type: {:s, 64}) # 时长

    # 计算总帧数: 10 + 20 + 30 = 60帧
    # 【帧级输入】 Shape: [1, 60]
    # 我们用 Nx.broadcast 生成全为某一个常数的张量来充当曲线
    f0          = Nx.broadcast(Nx.tensor(220.0, type: {:f, 32}), {1, 60}) # 假设全曲都是 220Hz (A3)
    breathiness = Nx.broadcast(Nx.tensor(0.0, type: {:f, 32}), {1, 60})
    voicing     = Nx.broadcast(Nx.tensor(1.0, type: {:f, 32}), {1, 60})
    gender      = Nx.broadcast(Nx.tensor(0.0, type: {:f, 32}), {1, 60})
    velocity    = Nx.broadcast(Nx.tensor(1.0, type: {:f, 32}), {1, 60})

    # 【全局输入 (浅层扩散参数)】 Shape: {} (标量)
    # 标量在 Nx 中直接用单值 tensor 表示
    depth = Nx.tensor(1000.0, type: {:f, 32})
    steps = Nx.tensor(100, type: {:s, 64})

    # 【严格对齐元组顺序】
    # 必须跟你之前 `show_session` 打印出的列表顺序一模一样
    {
      tokens,
      languages,
      durations,
      f0,
      breathiness,
      voicing,
      gender,
      velocity,
      depth,
      steps
    }
  end
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
