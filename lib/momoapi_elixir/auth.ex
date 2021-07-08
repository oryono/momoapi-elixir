defmodule MomoapiElixir.Auth do
  use HTTPoison.Base
  @base_url Application.get_env(:momoapi_elixir, :base_url) || "https://sandbox.momodeveloper.mtn.com"

  def process_request_url(url) do
    @base_url <> url
  end

  def authorise_collections(%{subscription_key: subscription_key} = config) do
    basic_auth_token = create_basic_auth_token(config)
    headers = [
      {"Authorization", "Basic #{basic_auth_token}"},
      {"Ocp-Apim-Subscription-Key", subscription_key}
    ]
    case post("/collection/token/", [], headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        %{"access_token" => access_token} = Poison.decode!(body)
        access_token
    end
  end

  def authorise_disbursements(%{subscription_key: subscription_key} = config) do
    basic_auth_token = create_basic_auth_token(config)
    headers = [
      {"Authorization", "Basic #{basic_auth_token}"},
      {"Ocp-Apim-Subscription-Key", subscription_key}
    ]
    case post("/disbursement/token/", [], headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        %{"access_token" => access_token} = Poison.decode!(body)
        access_token
    end
  end

  def create_basic_auth_token(%{user_id: user_id, api_key: api_key}) do
    Base.encode64("#{user_id}:#{api_key}")
  end
end