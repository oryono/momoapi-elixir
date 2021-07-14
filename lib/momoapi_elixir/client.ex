defmodule MomoapiElixir.Client do
  @moduledoc false
  use HTTPoison.Base
  @base_url Application.get_env(:momoapi_elixir, :base_url) || "https://sandbox.momodeveloper.mtn.com"

  def process_request_url(url) do
    @base_url <> url
  end
end