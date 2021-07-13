use Mix.Config

config :momoapi_elixir, http_client: MomoapiElixir.Collection.Client

import_config "#{Mix.env()}.exs"
