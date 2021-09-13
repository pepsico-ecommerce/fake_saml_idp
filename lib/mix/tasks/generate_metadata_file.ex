defmodule Mix.Tasks.FakeSamlIdp.GenerateMetadataFile do
  @moduledoc "Generate an XML SAML metadata file from the given public cert."
  @shortdoc "Generate an XML SAML metadata file."

  use Mix.Task

  alias FakeSamlIdp.Options

  import EEx

  @impl true
  def run([public_cert]) do
    cert = Options.public_cert_contents!(public_cert)

    if cert =~ "PRIVATE KEY" do
      Mix.shell().error("that looks like a private key, please provide a public certificate")
      exit({:shutdown, 1})
    end

    out_file = Path.join(File.cwd!(), "fake_idp_metadata.xml")
    metadata = render(%{cert: cert})

    File.write!(out_file, metadata)

    Mix.shell().info("Metadata file generated! Saved to \n\n  #{out_file}")
  end

  def run(args) do
    Mix.shell().info("USAGE:  mix fake_saml_idp.generate_metadata_file [/path/to/public/cert]\n")
    Mix.shell().error("expected exactly 1 arg(s), got: #{length(args)}")
    exit({:shutdown, 1})
  end

  @template Path.expand("../../fake_saml_idp/templates/metadata.xml.eex", __DIR__)
  function_from_file(:defp, :render, @template, [:assigns])
end
