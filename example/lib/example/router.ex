defmodule Example.Router do
  @moduledoc false

  use Plug.Router

  import EEx

  plug Plug.Logger

  plug Plug.Parsers, parsers: [:urlencoded]

  plug Plug.Session,
    store: :cookie,
    key: "_example_session",
    signing_salt: Application.get_env(:example, :signing_salt),
    encryption_salt: Application.get_env(:example, :encryption_salt),
    secret_key_base: Application.get_env(:example, :secret_key_base)

  plug :match
  plug :fetch_session
  plug :dispatch

  forward "/sso/fake_idp",
    to: FakeSamlIdp,
    init_opts: {Example.SSOConfig, :load_config, []}

  forward "/sso", to: Samly.Router

  # ---

  function_from_string(
    :defp,
    :render,
    """
    <div style="display: flex; flex-direction: column; align-items: center; justify-content: center; width: 100vw; height: 100vh">
      <%= if @assertion do %>
        <pre id="assertion" style="margin-bottom: 1rem"><%= inspect(@assertion, pretty: true) %></pre>
        <pre id="assertion-attrs" style="margin-bottom: 1rem"><%= Jason.encode!(@assertion.attributes, pretty: true) %></pre>
      <% end %>

      <a id="login-button" href="/sso/auth/signin/fake_idp">
       Login with SAML
      </a>

      <%= if @assertion do %>
        <a id="logout-button" href="/logout">
          Logout
        </a>
      <% end %>
    </div>
    """,
    [:assigns]
  )

  get "/" do
    assertion = Samly.get_active_assertion(conn)
    body = render(%{assertion: assertion})

    conn
    |> send_resp(200, body)
    |> halt()
  end

  get "/logout" do
    conn
    |> configure_session(drop: true)
    |> put_resp_header("Location", "/")
    |> send_resp(302, "")
    |> halt()
  end

  match _ do
    conn
    |> send_resp(404, "Not Found")
    |> halt()
  end
end
