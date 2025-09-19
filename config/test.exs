import Config

# Test-specific configuration
config :momoapi_elixir,
  http_client: ClientMock,
  base_url: "https://sandbox.momodeveloper.mtn.com",
  target_environment: "sandbox"