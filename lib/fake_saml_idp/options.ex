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
          public_cert: {plaintext :: String.t(), decoded :: binary()},
          private_key: term(),
          accounts: [%{String.t() => map()}]
        }

  defstruct enabled: true,
            public_cert: nil,
            private_key: nil,
            accounts: %{},
            resolved: %{}

  @doc """
  Construct an `%Options{}` struct.

  This will also read and decode the public certificate and private key,
  bailing out early if any errors are encountered.
  """
  @spec new(Keyword.t()) :: t()
  def new(opts) do
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

    plaintext =
      opts.public_cert
      |> read_file!()
      |> String.replace("-----BEGIN CERTIFICATE-----", "")
      |> String.replace("-----END CERTIFICATE-----", "")
      |> String.trim()
      |> String.replace("\n", "")

    decoded =
      plaintext
      |> Base.decode64()
      |> case do
        {:ok, decoded} -> decoded
        :error -> raise("unable to decode public certificate")
      end

    public_cert = {plaintext, decoded}

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

  defp read_file!(path) do
    case File.read(path) do
      {:ok, contents} -> contents
      {:error, reason} -> raise("unable to read #{path}: #{inspect(reason)}")
    end
  end
end
