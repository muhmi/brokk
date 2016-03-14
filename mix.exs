defmodule Brokk.Mixfile do
  use Mix.Project

  def project do
    [app: :brokk,
     version: "0.0.1",
     elixir: "~> 1.2",
     elixirc_paths: elixirc_paths(Mix.env),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :httpoison],
     mod: {Brokk, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:httpoison, "~> 0.8.0"},
     {:poison, "~> 2.0"}]
  end

  # LATER: Include some support code for :test
  defp elixirc_paths(:test), do: ["lib", "plugins", "test/plugins"]
  defp elixirc_paths(_), do: ["lib", "plugins"]
end
