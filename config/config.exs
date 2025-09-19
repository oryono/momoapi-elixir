import Config

# Base configuration - environment-specific configs will override these
config :momoapi_elixir,
  http_client: MomoapiElixir.Client

# Import environment-specific configuration
import_config "#{config_env()}.exs"
