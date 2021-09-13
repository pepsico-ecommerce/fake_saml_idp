defmodule FakeSamlIdp.Response do
  @moduledoc false

  alias FakeSamlIdp.Request

  import EEx

  @type xml :: SweetXml.xmlElement()

  @spec build(Request.t(), xml()) :: xml()
  def build(request, assertion) do
    %{
      id: request.id,
      now: DateTime.to_iso8601(request.now),
      dest: request.dest
    }
    |> render()
    |> SweetXml.parse()
    |> append_child(assertion)
  end

  @template Path.expand("templates/response.xml.eex", __DIR__)
  function_from_file(:defp, :render, @template, [:assigns])

  defp append_child(xml = {:xmlElement, _, _, _, _, _, _, _, children, _, _, _}, child) do
    xml
    |> Tuple.delete_at(8)
    |> Tuple.insert_at(8, children ++ [child])
  end
end
