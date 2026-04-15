defmodule Bunch.MixProject do
  use Mix.Project

  @version "1.6.3"
  @github_url "https://github.com/membraneframework/bunch"

  def project do
    [
      app: :bunch,
      version: @version,
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: dialyzer(),

      # hex
      description: "Generic Elixir helper functions and macros used across Membrane.",
      package: package(),

      # docs
      name: "Bunch",
      source_url: @github_url,
      homepage_url: "https://membraneframework.org",
      docs: docs(),
      aliases: [docs: ["docs", &prepend_llms_links/1]]
    ]
  end

  def application do
    [extra_applications: [:crypto, :logger]]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "LICENSE"],
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
      {:ex_doc, "~> 0.40", only: :dev, runtime: false},
      {:credo, "~> 1.6", only: :dev, runtime: false},
      {:dialyxir, "~> 1.1", only: :dev, runtime: false}
    ]
  end

  defp dialyzer() do
    opts = [
      flags: [:error_handling]
    ]

    if System.get_env("CI") == "true" do
      # Store PLTs in cacheable directory for CI
      [plt_local_path: "priv/plts", plt_core_path: "priv/plts"] ++ opts
    else
      opts
    end
  end

defp prepend_llms_links(_) do
  path = "doc/llms.txt"

  if File.exists?(path) do
    existing = File.read!(path)

    header =
      "- [Membrane Core AI Skill](https://hexdocs.pm/membrane_core/skill.md)\n" <>
        "- [Membrane Core](https://hexdocs.pm/membrane_core/llms.txt)\n\n"

    File.write!(path, header <> existing)
  end
end

end
