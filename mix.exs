defmodule Bunch.MixProject do
  use Mix.Project

  def project do
    [
      app: :bunch,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      preferred_cli_env: [espec: :test, format: :test],
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:espec, "~> 1.6", only: :test}
    ]
  end
end
