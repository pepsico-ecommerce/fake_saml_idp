defmodule FakeSamlIdp.Controller do
  @moduledoc false

  import Plug.Conn
  import EEx

  alias FakeSamlIdp.{Assertion, Request, Response, Options}

  require Logger

  @spec login_form(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def login_form(conn, %{"SAMLRequest" => saml_request, "RelayState" => relay_state}) do
    options = conn.private[:fake_saml_idp]

    resp =
      render_login_form(%{
        accounts: options.accounts,
        saml_request: saml_request,
        relay_state: relay_state
      })

    conn
    |> send_resp(200, resp)
    |> halt()
  end

  def login_form(conn, _params) do
    conn
    |> send_resp(400, "Bad Request")
    |> halt()
  end

  @template Path.expand("templates/login.html.eex", __DIR__)
  function_from_file(:defp, :render_login_form, @template, [:assigns])

  @spec handle_login(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def handle_login(conn, params = %{"SAMLRequest" => saml_request, "RelayState" => relay_state}) do
    options = conn.private[:fake_saml_idp]

    with {:decode_b64, {:ok, saml_request}} <- {:decode_b64, Base.decode64(saml_request)},
         {:decode_xml, {:ok, saml_request}} <- {:decode_xml, parse_xml(saml_request)},
         {:request, {:ok, request}} <- {:request, Request.parse(saml_request)},
         {:email, {:ok, email}} <- {:email, Map.fetch(params, "email")},
         {:account, {:ok, account}} <- {:account, find_account(email, options)} do
      assertion =
        request
        |> Assertion.build(account)
        |> sign_xml(options)

      response =
        request
        |> Response.build(assertion)
        |> sign_xml(options)

      body = :esaml_binding.encode_http_post(request.dest, response, relay_state)

      conn
      |> send_resp(200, body)
      |> halt()
    else
      error ->
        Logger.error("error handling SAML login: #{inspect(error)}")

        conn
        |> send_resp(400, "Bad Request")
        |> halt()
    end
  end

  def handle_login(conn, _params) do
    conn
    |> send_resp(400, "Bad Request")
    |> halt()
  end

  # TODO: implement logout
  @spec handle_logout(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def handle_logout(conn, _params) do
    send_resp(conn, 500, "Not Implemented")
  end

  # ---

  defp find_account(email, %Options{accounts: accounts}) do
    case Enum.find(accounts, &(&1["email"] == email)) do
      nil -> {:error, "no account found for #{email}"}
      account -> {:ok, account}
    end
  end

  defp parse_xml(xml_string) do
    try do
      {:ok, SweetXml.parse(xml_string, quiet: true)}
    catch
      :exit, reason ->
        {:error, reason}
    end
  end

  defp sign_xml(xml, %Options{public_cert: cert, private_key: key}) do
    :xmerl_dsig.sign(xml, key, cert)
  end
end
