defmodule Pitcher.MixProject do
  use Mix.Project

  def project(),
    do: [
      app: :pitcher_logger_backend,
      version: "0.0.1",
      elixir: "~> 1.9",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      docs: [
        extras: ["README.md", "LICENSE.md"],
        main: "readme"
      ]
    ]

  def application(),
    do: [
      extra_applications: [:logger]
    ]

  defp deps(),
    do: [
      {:httpoison, "~> 1.5"}
    ]

  defp description,
    do: """
    A REST Logger backend
    """

  defp package(),
    do: [
      files: ["config", "lib", "mix.exs", "README*", "LICENSE*", "CHANGELOG*"],
      maintainers: ["Jahred Love"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/Lazarus404/pitcher_logger_backend"}
    ]
end
