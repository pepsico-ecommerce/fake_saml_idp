defmodule Example.MixProject do
  use Mix.Project

  def project do
    [
      app: :example,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Example.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:cowboy, "~> 2.9", override: true},
      {:fake_saml_idp, path: ".."},
      {:hound, "~> 1.1", only: :test},
      {:jason, "~> 1.2"},
      {:plug, "~> 1.12"},
      {:plug_cowboy, "~> 2.3"},
      {:samly, "~> 1.0"}
    ]
  end
end
