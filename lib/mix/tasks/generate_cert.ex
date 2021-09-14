defmodule Mix.Tasks.FakeSamlIdp.GenerateCert do
  @moduledoc "Generate a public cert and private key, suitable for use with SAML."
  @shortdoc "Generate a public cert and private key."

  use Mix.Task

  import EEx

  @cert_request_fields [
    country: {"Country", "US"},
    state: {"State/Province", "New York"},
    locality: {"Locality", "New York"},
    organization: {"Organization", "PepsiCo, Inc."},
    division: {"Division", "Global eCommerce - Digital Technology & Experience"},
    name: {"Name", "eCommerce Automation Platform - Prod"},
    email: {"Email", "email@pepsico.com"}
  ]

  @out_file "/tmp/cert_request.ini"

  @impl true
  def run([]) do
    assigns =
      for {field, {message, default}} <- @cert_request_fields, into: %{} do
        {field, prompt(message, default)}
      end

    cert_request = render(assigns)
    File.write!(@out_file, cert_request)
    run(["--req", @out_file])
  end

  def run(["--req", req_file]) do
    cwd = File.cwd!()
    cert_file = Path.join(cwd, "fake_idp.crt")
    key_file = Path.join(cwd, "fake_idp.pem")

    cmd!("openssl", [
      "req",
      "-x509",
      "-sha256",
      "-nodes",
      "-newkey",
      "rsa:2048",
      "-days",
      "365",
      "-keyout",
      key_file,
      "-out",
      cert_file,
      "-config",
      req_file
    ])

    # clean up if we used the template
    File.rm(@out_file)

    Mix.shell().info("Certificate and key files generated! Saved to \n")
    Mix.shell().info("  #{cert_file}")
    Mix.shell().info("  #{key_file}")
  end

  def run(_) do
    Mix.shell().info("USAGE:  mix fake_saml_idp.generate_cert [--req /path/to/cert/request]\n")
    Mix.shell().info("    --req   path to an OpenSSL certificate request (.ini file)\n")
    Mix.shell().error("invalid arguments")
    exit({:shutdown, 1})
  end

  @template Path.expand("templates/cert_request.ini.eex", __DIR__)
  function_from_file(:defp, :render, @template, [:assigns])

  defp prompt(message, default) do
    resp =
      [message, :faint, " (#{default})", :reset, ": "]
      |> IO.ANSI.format()
      |> to_string()
      |> Mix.shell().prompt()

    case String.trim(resp) do
      "" -> default
      resp -> resp
    end
  end

  defp cmd!(bin, args) do
    {_, code} = System.cmd(bin, args, stderr_to_stdout: true, into: IO.stream(:stdio, :line))

    unless code == 0 do
      Mix.shell().error("command exited with non-zero exit code\n")
      Mix.shell().error("  #{bin} #{Enum.join(args, " ")}")
      exit({:shutdown, 1})
    end
  end
end
