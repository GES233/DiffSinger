defmodule DiffSinger.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :diff_singer,
      version: @version,
      build_path: "_build",
      config_path: "config/config.exs",
      deps_path: "deps",
      lockfile: "mix.lock",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [flags: [:no_opaque, :no_contracts]]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {DiffSinger.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nx, "~> 0.8"},
      # Use it until my fork can running ONNXRuntime
      # on Intel Arc via OpenVINO EP.
      {:ortex, git: "https://github.com/elixir-nx/ortex"},
      {:yaml_elixir, "~> 2.12"},
      {:jason, "~> 1.4"},
      # Orchestration
      {:orchid, "~> 0.5"},
      {:orchid_symbiont, "~> 0.1"},
      {:lily, git: "https://github.com/SynapticStrings/Lily.git"}
    ]
  end
end
