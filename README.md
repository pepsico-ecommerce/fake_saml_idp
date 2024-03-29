# Fake SAML identity provider

This app provides a plug, `FakeSamlIdp`, that you can host within your
existing Plug application to serve as a mock SAML identity provider. It
will receive well-formed SAML login requests, process them, and return
a well-formed SAML response on valid input. It also provides a basic login
page, allowing it to act as a drop-in replacement for a full-featured
SAML authentication provider.

## Usage

In most cases, setup should be as easy as adding

```elixir
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
```

to your router.

## Configuration

Configuration may be provided directly to the `FakeSamlIdp` plug, usually
when invoking the `forward` macro. You may also configure everything in
`config.exs`, and load from there instead:

```elixir
# config.exs

config :my_app, FakeSamlIdp,
  public_cert: "/path/to/public/cert",
  private_key: "/path/to/private/key",
  accounts: [ ... ]

# router.ex

forward "/sso/fake_idp",
  to: FakeSamlIdp,
  init_opts: Application.get_env(:my_app, FakeSamlIdp)
```

Additionally, you may provide configuration dynamically at runtime by
providing an MFA tuple to `:init_opts`:

```elixir
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
```

See `FakeSamlIdp.Options` for detailed configuration options.

## Integrating with Samly

[Samly](https://hexdocs.pm/samly) is a popular Elixir-based SAML adapter.
Integration with `FakeSamlIdp` is straightforward:

```elixir
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
      signed_envelopes_in_resp: false
    }
  ]
```

Make sure you're using the same public cert/private key in `:service_providers`
that you're using with `FakeSamlIdp`, or the handshake won't complete. To generate
a metadata file, you can use the included mix task

```sh
mix fake_saml_idp.generate_metadata "/path/to/public/cert"
```

This will generate an XML metadata file that assumes your fake SAML IDP will be
mounted at `/sso/fake_idp`. If this is **not** the case, make sure to edit the
`SingleSignOnService` and `SingleLogoutService` endpoints accordingly.

If you need a public cert and private key as well, you can use the other mix task

```sh
mix fake_saml_idp.generate_cert
```

## Credits

Original idea and implementation (and a bit of black magic) by
[@cjfreeze](https://github.com/cjfreeze).

&copy; 2021 PepsiCo, Inc., all rights reserved.
