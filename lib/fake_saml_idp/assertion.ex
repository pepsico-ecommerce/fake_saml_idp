defmodule FakeSamlIdp.Assertion do
  @moduledoc false

  import EEx

  alias FakeSamlIdp.Request

  @type xml :: SweetXml.xmlElement()

  @spec build(Request.t(), map()) :: xml()
  def build(request, account) do
    %{
      account: account,
      now: DateTime.to_iso8601(request.now),
      later: DateTime.to_iso8601(request.later),
      dest: request.dest,
      urn: request.urn
    }
    |> render()
    |> SweetXml.parse()
  end

  @template Path.expand("templates/assertion.xml.eex", __DIR__)
  function_from_file(:defp, :render, @template, [:assigns])
end
