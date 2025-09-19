import Config

# Production configuration
config :momoapi_elixir,
  base_url: "https://momoapi.mtn.com",
  target_environment: "production"

# OPTION 1: Environment Variables (Recommended)
# Set these environment variables in your production environment:
# export MOMO_SUBSCRIPTION_KEY="your_production_subscription_key"
# export MOMO_USER_ID="your_production_user_id"
# export MOMO_API_KEY="your_production_api_key"
# export MOMO_TARGET_ENVIRONMENT="production"
#
# Then use: {:ok, config} = MomoapiElixir.Config.from_env()

# OPTION 2: Application Config (Alternative)
# Uncomment and set these if you prefer config-based credentials:
# config :momoapi_elixir,
#   subscription_key: System.get_env("MOMO_SUBSCRIPTION_KEY"),
#   user_id: System.get_env("MOMO_USER_ID"),
#   api_key: System.get_env("MOMO_API_KEY")
#
# Then use: {:ok, config} = MomoapiElixir.Config.from_app_config()