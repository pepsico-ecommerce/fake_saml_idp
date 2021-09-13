defmodule FakeSamlIdp.MixProject do
  use Mix.Project

  def project do
    [
      app: :fake_saml_idp,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
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
      {:esaml, "~> 4.2"},
      {:ex_doc, "~> 0.24", only: :dev},
      {:plug, "~> 1.12"},
      {:sweet_xml, "~> 0.7"}
    ]
  end
end
