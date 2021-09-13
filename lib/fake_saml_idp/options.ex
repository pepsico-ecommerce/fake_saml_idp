defmodule FakeSamlIdp.Options do
  @moduledoc """
  Options for configuring the FakeSamlIdp plug.

  ## Options

  - `:enabled` - whether the fake SAML IDP should be enabled (default: `true`)
  - `:public_cert` - path to a public certificate (required)
  - `:private_key` - path to the corresponding private key (required)
  - `:accounts` - list of account details (must include `"email"` for each) (required)

  """

  @type t :: %__MODULE__{
          enabled: boolean(),
          public_cert: binary(),
          private_key: term(),
          accounts: [%{String.t() => map()}]
        }

  defstruct enabled: true,
            public_cert: nil,
            private_key: nil,
            accounts: []

  @doc """
  Construct an `%Options{}` struct.

  This will also read and decode the public certificate and private key,
  bailing out early if any errors are encountered.

  ## Runtime Config

  If you'd like to configure the IDP at runtime, you may instead supply
  an MFA tuple, which will be invoked to generate options on each request.
  This MFA should return a keyword list of options.
  """
  @spec new(mfa() | Keyword.t()) :: t()
  def new(_mfa = {module, function, args}) do
    module
    |> apply(function, args)
    |> new()
  end

  def new(opts) when is_list(opts) do
    opts = struct!(__MODULE__, opts)

    unless map_size(opts.accounts) > 0 do
      raise "must provide at least one SAML account"
    end

    unless Enum.all?(opts.accounts, &Map.has_key?(&1, "email")) do
      raise "must provide `email` for all SAML accounts"
    end

    unless opts.public_cert && opts.private_key do
      raise "must provide both a public certificate and private key"
    end

    public_cert =
      opts.public_cert
      |> public_cert_contents()
      |> Base.decode64()
      |> case do
        {:ok, decoded} -> decoded
        :error -> raise("unable to decode public certificate")
      end

    private_key =
      opts.private_key
      |> read_file!()
      |> :public_key.pem_decode()
      |> case do
        [pem_entry] ->
          :public_key.pem_entry_decode(pem_entry)

        [] ->
          raise "private key must contain exactly 1 entry (got: 0)"

        pem_entries ->
          raise "private key must contain exactly 1 entry (got: #{length(pem_entries)})"
      end

    %{opts | public_cert: public_cert, private_key: private_key}
  end

  @doc false
  @spec public_cert_contents(Path.t()) :: String.t()
  def public_cert_contents(path) do
    path
    |> read_file!()
    |> String.replace("-----BEGIN CERTIFICATE-----", "")
    |> String.replace("-----END CERTIFICATE-----", "")
    |> String.trim()
    |> String.replace("\n", "")
  end

  defp read_file!(path) do
    case File.read(path) do
      {:ok, contents} -> contents
      {:error, reason} -> raise("unable to read #{path}: #{inspect(reason)}")
    end
  end
end
