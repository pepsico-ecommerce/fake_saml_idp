defmodule FakeSamlIdp.Router do
  @moduledoc false

  use Plug.Router

  import Plug.Conn

  alias FakeSamlIdp.Controller

  plug Plug.Logger

  plug :match
  plug :fetch_query_params
  plug :dispatch

  get "/login", do: Controller.login_form(conn, conn.params)

  post "/login", do: Controller.handle_login(conn, conn.params)

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
