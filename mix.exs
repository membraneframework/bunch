defmodule Bunch.MixProject do
  use Mix.Project

  @version "0.3.0"
  @github_url "https://github.com/membraneframework/bunch"

  def project do
    [
      app: :bunch,
      version: @version,
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      app: :bunch,
      name: "Bunch",
      description: "A bunch of helper functions, intended to make life easier",
      package: package(),
      source_url: @github_url,
      docs: docs(),
      deps: deps()
    ]
  end

  def application do
    [extra_applications: []]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      source_ref: "v#{@version}"
    ]
  end

  defp package do
    [
      maintainers: ["Membrane Team"],
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => @github_url,
        "Membrane Framework Homepage" => "https://membraneframework.org"
      }
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
    ]
  end
end
