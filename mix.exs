defmodule SharesightDesktop.MixProject do
  use Mix.Project

  def project do
    [
      app: :sharesight_desktop,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :wx],
      mod: {SharesightDesktop.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 2.0"}
    ]
  end
end
