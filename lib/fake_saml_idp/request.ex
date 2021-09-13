defmodule FakeSamlIdp.Request do
  @moduledoc false

  import SweetXml, only: [sigil_x: 2]

  alias FakeSamlIdp.Options

  @type xml :: SweetXml.xmlElement()

  @type t :: %__MODULE__{
          id: String.t(),
          urn: String.t(),
          dest: String.t(),
          cert: String.t(),
          now: DateTime.t(),
          later: DateTime.t()
        }

  @enforce_keys [:urn, :dest, :cert]
  defstruct urn: nil, dest: nil, cert: nil

  @spec parse(xml()) :: {:ok, t()} | {:error, String.t()}
  def parse(saml_request, %Options{public_cert: {plaintext, _decoded}}) do
    with {:ok, id} <- xpath(saml_request, ~x"//saml:AuthnRequest/@ID"),
         {:ok, urn} <- xpath(saml_request, ~x"//saml:Issuer/text()"),
         {:ok, dest} <- xpath(saml_request, ~x"//samlp:AuthnRequest/@AssertionConsumerServiceURL") do
      now = DateTime.utc_now()
      later = DateTime.add(now, 120, :second)

      {:ok, %__MODULE__{id: id, urn: urn, dest: dest, cert: plaintext, now: now, later: later}}
    end
  end

  defp xpath(parent, selector) do
    case SweetXml.xpath(parent, selector) do
      nil -> {:error, "xpath selector failed: #{selector.path}"}
      output -> {:ok, output}
    end
  end
end
