defmodule Example.SSOPipeline do
  @moduledoc false

  use Plug.Builder

  plug :compute_attributes

  def compute_attributes(conn, _opts) do
    assertion = conn.private[:samly_assertion]
    IO.inspect(assertion, label: "SAML assertion")

    conn
  end
end
