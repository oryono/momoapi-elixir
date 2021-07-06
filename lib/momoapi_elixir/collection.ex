defmodule MomoapiElixir.Collection do
  use HTTPoison.Base

  @base_url Application.get_env(:momoapi_elixir, :base_url) || "https://sandbox.momodeveloper.mtn.com"

  @config %{
    subscription_key: Application.get_env(:momoapi_elixir, :collections_subscription_key),
    user_id: Application.get_env(:momoapi_elixir, :collections_user_id),
    api_key: Application.get_env(:momoapi_elixir, :collections_api_key),
    callback_url: Application.get_env(:momoapi_elixir, :collections_callback_url),
    target_environment: Application.get_env(:momoapi_elixir, :target_environment)
  }

  def process_request_url(url) do
    @base_url <> url
  end

  def process_request_headers(headers) do
    headers |> set_subscription_key(@config.subscription_key) |> set_target_environment(@config.target_environment || "sandbox")
  end

  def process_response_body(body) do
    body |> Poison.decode!()
  end

  @doc """
  This operation is used to request a payment from a consumer (Payer). The payer will be asked to authorize the payment.
  The transaction will be executed once the payer has authorized the payment. The requesttopay will be in status PENDING
  until the transaction is authorized or declined by the payer or it is timed out by the system. Status of the transaction
  can be validated by using the GET /requesttopay/<resourceId>

  %{
    amount: "50",
    currency: "EUR",
    externalId: "123456",
    payer: %{
      partyIdType: "MSISDN",
      partyId: "256784275529"
    },
    payerMessage: "testing",
    payeeNote: "hello"
  }

  """
  def request_to_pay(body) do
    token = MomoapiElixir.Auth.authorise_collections(@config)
    headers = add_reference_id(reference_id()) |> add_token(token)
    request_to_pay(headers, body)
  end

  defp request_to_pay(headers, body) do
    case post("/collection/v1_0/requesttopay", Poison.encode!(body), headers) do
      {:ok, %HTTPoison.Response{status_code: 202, body: _body}} -> reference_id
    end
  end

  @doc"""
  Get the balance of the account
  """
  def get_balance do
    token = MomoapiElixir.Auth.authorise_collections(@config)
    headers = add_reference_id(reference_id()) |> add_token(token)
    get_balance(headers)
  end

  defp get_balance(headers) do
    case get("/collection/v1_0/account/balance", headers) do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} -> body
    end
  end


  @doc """
  This method is used to retrieve transaction information. You can invoke it at intervals until your transaction fails or succeeds
  """
  def get_transaction_status(reference_id) do
    token = MomoapiElixir.Auth.authorise_collections(@config)
    headers = add_reference_id(reference_id()) |> add_token(token)
    get_transaction_status(headers, reference_id)
  end

  def get_transaction_status(headers, reference_id) do
    case get("/collection/v1_0/requesttopay/#{reference_id}", headers) do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} -> body
    end
  end

  defp reference_id do
    UUID.uuid4()
  end

  defp set_subscription_key(headers \\ [], subscription_key) do
    [{"Ocp-Apim-Subscription-Key", subscription_key} | headers]
  end

  defp set_target_environment(headers \\ [], target_environment) do
    [{"X-Target-Environment", target_environment} | headers]
  end

  defp add_reference_id(headers \\ [], reference_id) do
    [{"X-Reference-Id", reference_id} | headers]
  end

  defp add_token(headers \\ [], token) do
    [{"Authorization", "Bearer #{token}"} | headers]
  end
end
