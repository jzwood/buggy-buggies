defmodule LiveBuggies.MixProject do
  use Mix.Project

  def project do
    [
      app: :live_buggies,
      version: "0.1.0",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {LiveBuggies.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:esbuild, "~> 0.4", runtime: Mix.env() == :dev},
      {:floki, ">= 0.30.0", only: :test},
      {:gettext, "~> 0.18"},
      {:jason, "~> 1.2"},
      {:phoenix, "~> 1.6.15"},
      {:phoenix_html, "~> 3.2.0"},
      {:phoenix_live_reload, "~> 1.4.1", only: :dev},
      {:phoenix_live_view, "~> 0.18.11"},
      {:plug_cowboy, "~> 2.5"},
      {:rivet_utils, "~> 1.0"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:uuid, "~> 1.1"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get"],
      "assets.deploy": ["esbuild default --minify", "phx.digest"],
      start: ["phx.server"],
      c: ["compile"]
    ]
  end
end
