use Mix.Config

config :momoapi_elixir, http_client: MomoapiElixir.Client

import_config "#{Mix.env()}.exs"
