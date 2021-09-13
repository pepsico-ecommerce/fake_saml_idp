defmodule FakeSamlIdp do
  @moduledoc """
  Fake SAML identity provider.

  TODO: write usage docs
  """

  import Plug.Conn

  alias FakeSamlIdp.{Router, Options}

  @router_opts Router.init([])

  @behaviour Plug

  @impl true
  def init(opts), do: Options.new(opts)

  @impl true
  def call(conn, %Options{enabled: false}) do
    conn
    |> send_resp(404, "Not Found")
    |> halt()
  end

  def call(conn, %Options{} = opts) do
    conn
    |> put_private(:fake_saml_idp, opts)
    |> Router.call(@router_opts)
  end
end
