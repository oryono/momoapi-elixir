defmodule MomoapiElixir.Collection do
  use GenServer

  defmodule Option do
    @enforce_keys ~w(subscription_key user_id api_key)a
    defstruct subscription_key: nil, user_id: nil, api_key: nil, callback_url: nil, target_environment: "sandbox"
  end

  defmodule Client do
    use HTTPoison.Base
    @base_url Application.get_env(:momoapi_elixir, :base_url) || "https://sandbox.momodeveloper.mtn.com"

    def process_request_url(url) do
      @base_url <> url
    end
  end

  def start(%Option{} = opts) do
    GenServer.start(__MODULE__, opts, name: __MODULE__)
  end

  # Client
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
      partyId: "46733123450"
    },
    payerMessage: "testing",
    payeeNote: "hello"
  }

  """
  def request_to_pay(body) do
    body = validate_collections(body)
    GenServer.call(__MODULE__, {:request_to_pay, body})
  end

  @doc"""
  Get the balance of the account
  """
  def get_balance do
    GenServer.call(__MODULE__, :get_balance)
  end

  @doc """
  This method is used to retrieve transaction information. You can invoke it at intervals until your transaction fails or succeeds
  """
  def get_transaction_status(reference_id) do
    GenServer.call(__MODULE__, {:get_transaction_status, reference_id})
  end

  # Callbacks
  def init(%Option{subscription_key: subscription_key, user_id: user_id, api_key: api_key}) do
    token = MomoapiElixir.Auth.authorise_collections(
      %{subscription_key: subscription_key, user_id: user_id, api_key: api_key}
    )
    {:ok, %{subscription_key: subscription_key, token: token}}
  end

  def handle_call({:request_to_pay, body}, _from, state) do
    reference_id = reference_id()
    body_encoded = Poison.encode!(body)
    headers = [
      {"Authorization", "Bearer #{state.token}"},
      {"Ocp-Apim-Subscription-Key", state.subscription_key},
      {"X-Reference-Id", reference_id},
      {"X-Target-Environment", "sandbox"}
    ]
    case Client.post("/collection/v1_0/requesttopay", body_encoded, headers) do
      {:ok, %HTTPoison.Response{status_code: 202, body: _body}} -> {:reply, reference_id, state}
      {:ok, %HTTPoison.Response{status_code: 500, body: body}} -> {:reply, {:error, %{code: 500, body: Poison.decode!(body)}}, state}
      {:ok, %HTTPoison.Response{status_code: 500, body: ""}} -> {:reply, {:error, %{code: 500, body: ""}}, state }
      {:ok, %HTTPoison.Response{status_code: 400, body: ""}} -> {:reply, {:error, %{code: 400, body: ""}}, state}
      {:ok, %HTTPoison.Response{status_code: 400, body: body}} -> {:reply, {:error, %{code: 400, body: Poison.decode!(body)}}, state}
    end
  end

  def handle_call(:get_balance, _from, state) do
    headers = [
      {"Authorization", "Bearer #{state.token}"},
      {"Ocp-Apim-Subscription-Key", state.subscription_key},
      {"X-Target-Environment", "sandbox"}
    ]
    case Client.get("/collection/v1_0/account/balance", headers) do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} -> {:reply, Poison.decode!(body), state}
      {:ok, %HTTPoison.Response{body: body, status_code: 404}} -> {:reply, {:error, Poison.decode!(body)}, state}
      {:ok, %HTTPoison.Response{body: body, status_code: 500}} -> {:reply, {:error, Poison.decode!(body)}, state}
    end
  end

  def handle_call({:get_transaction_status, reference_id}, _from, state) do
    headers = [
      {"Authorization", "Bearer #{state.token}"},
      {"Ocp-Apim-Subscription-Key", state.subscription_key},
      {"X-Target-Environment", "sandbox"},
      {"X-Reference-Id", reference_id},
    ]
    case Client.get("/collection/v1_0/requesttopay/#{reference_id}", headers) do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} -> {:reply, Poison.decode!(body), state}
    end

  end

  defp reference_id do
    UUID.uuid4()
  end

  defp validate_collections(
        %{
          amount: amount
        }
      ) when is_nil(amount) or amount == "" do
    raise "Amount is required"
  end

  defp validate_collections(
        %{
          currency: currency
        }
      ) when is_nil(currency) or currency == "" do
    raise "Currency is required"
  end

  defp validate_collections(
        %{
          payer: %{
            partyId: party_id
          },
        }
      ) when is_nil(party_id) or party_id == "" do
    raise "Party id is required"
  end

  defp validate_collections(body) do
    body
  end
end
