use Mix.Config

sso_dir = "priv/sso"

public_cert = Path.expand("fake_idp.crt", sso_dir)
private_key = Path.expand("fake_idp.pem", sso_dir)

config :example, FakeSamlIdp,
  public_cert: public_cert,
  private_key: private_key,
  accounts: [
    %{
      "email" => "admin@example.com",
      "firstName" => "Admin",
      "lastName" => "User",
      "userId" => "0123456"
    }
  ]

config :samly, Samly.Provider,
  idp_id_from: :path_segment,
  service_providers: [
    %{
      id: "example_app",
      entity_id: "urn:example.dev:example-app",
      certfile: public_cert,
      keyfile: private_key
    }
  ],
  identity_providers: [
    %{
      id: "fake_idp",
      sp_id: "example_app",
      base_url: "http://localhost:4321/sso",
      metadata_file: Path.expand("fake_idp_metadata.xml", sso_dir),
      nameid_format: "entity",
      pre_session_create_pipeline: Example.SSOPipeline,
      signed_envelopes_in_resp: false
    }
  ]

config :example,
  signing_salt: "MiaGcc6lSQO0F7Y+bWrLCEk6h8F2s8NFuSXH8",
  encryption_salt: "FuSXH80qdqW/wRyl867lI394maJiww8ASdS5dys",
  secret_key_base:
    "pdk/uTi1FbxnHy0MV1rLvCQtD7b+Q4EBlowUenS7UdbdRBrSZfkmY/PJJDjqPgaqmFQliFyAvK2jbAN4kGrbJw"
