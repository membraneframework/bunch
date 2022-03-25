defmodule Bunch.MixProject do
  use Mix.Project

  @version "1.3.0"
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
    [extra_applications: [:crypto]]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      formatters: ["html"],
      source_ref: "v#{@version}",
      nest_modules_by_prefix: [Bunch]
    ]
  end

  defp package do
    [
      maintainers: ["Membrane Team"],
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @github_url,
        "Membrane Framework Homepage" => "https://membraneframework.org"
      }
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.28", only: :dev, runtime: false},
      {:dialyxir, "~> 1.1", only: :dev, runtime: false}
    ]
  end
end
