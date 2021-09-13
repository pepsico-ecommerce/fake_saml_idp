defmodule FakeSamlIdp do
  @moduledoc """
  Fake SAML identity provider.

  ## Usage

  This app provides a plug, `FakeSamlIdp`, that you can host within your
  existing Plug application to serve as a mock SAML identity provider. It
  will receive well-formed SAML login requests, process them, and return
  a well-formed SAML response on valid input. It also provides a basic login
  page, allowing it to act as a drop-in replacement for a full-featured
  SAML authentication provider.

  In most cases, setup should be as easy as adding

      forward "/sso/fake_idp",
        to: FakeSamlIdp,
        public_cert: "/path/to/public/cert",
        private_key: "/path/to/private/key",
        accounts: [
          %{
            "email" => "admin@example.com",
            "firstName" => "Admin",
            "lastName" => "User",
            "userId" => "123456"
          }
        ]

  to your router.

  ## Configuration

  Configuration may be provided directly to the `FakeSamlIdp` plug, usually
  when invoking the `forward` macro. You may also configure everything in
  `config.exs`, and load from there instead:

      # config.exs

      config :my_app, FakeSamlIdp,
        public_cert: "/path/to/public/cert",
        private_key: "/path/to/private/key",
        accounts: [ ... ]

      # router.ex

      forward "/sso/fake_idp",
        to: FakeSamlIdp,
        init_opts: Application.get_env(:my_app, FakeSamlIdp)

  Additionally, you may provide configuration dynamically at runtime by
  providing an MFA tuple to `:init_opts`:

      # router.ex

      forward "/sso/fake_idp",
        to: FakeSamlIdp,
        init_opts: {RuntimeConfig, :load_idp_config, []}

      # my_app.ex

      defmodule RuntimeConfig do
        @config [
          public_cert: "...",
          private_key: "..."
        ]

        def load_idp_config do
          Keyword.merge(@config, accounts: [...])
        end
      end

  See `FakeSamlIdp.Options` for detailed configuration options.

  ## Integrating with Samly

  [Samly](https://hexdocs.pm/samly) is a popular Elixir-based SAML adapter.
  Integration with `FakeSamlIdp` is straightforward:

      # config.exs

      config :samly, Samly.Provider,
        idp_id_from: :path_segment,
        service_providers: [
          %{
            id: "my_app",
            entity_id: "urn:myapp.dev:auth-entity",
            certfile: "/path/to/public/cert",
            keyfile: "/path/to/private/key"
          }
        ],
        identity_providers: [
          %{
            id: "fake_saml_idp",
            sp_id: "my_app",
            base_url: "http://localhost:4000/sso",
            metadata_file_location: "/path/to/metadata/file",
            nameid_format: "entity",
            pre_session_create_pipeline: MyApp.SAMLPipeline,
            # FIXME: check if this is actually required
            signed_envelopes_in_resp: false
          }
        ]

  Make sure you're using the same public cert/private key in `:service_providers`
  that you're using with `FakeSamlIdp`, or the handshake won't complete. To generate
  a metadata file, you can use the included mix task

      mix fake_saml_idp.generate_metadata_file "/path/to/public/cert"

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
