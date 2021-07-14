defmodule MomoapiElixir.Disbursement do
  use GenServer

  defmodule Option do
    @enforce_keys ~w(subscription_key user_id api_key)a
    defstruct subscription_key: nil, user_id: nil, api_key: nil, callback_url: nil, target_environment: "sandbox"
  end

  defmodule DisbursementClient do
    @client Application.get_env(:momoapi_elixir, :http_client)

    def transfer(body, headers) do
      body = MomoapiElixir.Validator.validate_disbursements(body)
      @client.post("/disbursement/v1_0/transfer", Poison.encode!(body), headers)
    end

    def get_balance(headers) do
      @client.get("/disbursement/v1_0/account/balance", headers)
    end

    def get_transaction_status(reference_id, headers) do
      @client.get("/disbursement/v1_0/transfer/#{reference_id}", headers)
    end
  end

  def start(%Option{} = opts) do
    GenServer.start(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  %{
      amount: "100",
      currency: "EUR",
      externalId: "947354",
      payee: %{
        partyIdType: "MSISDN",
        partyId: "+256776564739"
      },
      payerMessage: "testing",
      payeeNote: "hello"
  }
  """

  def transfer(body) do
    body = MomoapiElixir.Validator.validate_disbursements(body)
    GenServer.call(__MODULE__, {:transfer, body})
  end

  def get_balance do
    GenServer.call(__MODULE__, :get_balance)
  end

  def get_transaction_status(reference_id) do
    GenServer.call(__MODULE__, {:get_transaction_status, reference_id})
  end

  # Callbacks
  def init(%Option{subscription_key: subscription_key, user_id: user_id, api_key: api_key}) do
    token = MomoapiElixir.Auth.authorise_disbursements(
      %{subscription_key: subscription_key, user_id: user_id, api_key: api_key}
    )
    {:ok, %{subscription_key: subscription_key, token: token}}
  end

  def handle_call({:transfer, body}, _from, state) do
    reference_id = reference_id()
    headers = [
      {"Authorization", "Bearer #{state.token}"},
      {"Ocp-Apim-Subscription-Key", state.subscription_key},
      {"X-Reference-Id", reference_id},
      {"X-Target-Environment", "sandbox"}
    ]
    case DisbursementClient.transfer(body, headers) do
      {:ok, %HTTPoison.Response{status_code: 202, body: _body}} ->
        {:reply, reference_id, state}
      {:ok, %HTTPoison.Response{status_code: 500, body: body}} ->
        {:reply, {:error, %{code: 500, body: Poison.decode!(body)}}, state}
      {:ok, %HTTPoison.Response{status_code: 500, body: ""}} ->
        {:reply, {:error, %{code: 500, body: ""}}, state}
      {:ok, %HTTPoison.Response{status_code: 400, body: ""}} ->
        {:reply, {:error, %{code: 400, body: ""}}, state}
      {:ok, %HTTPoison.Response{status_code: 400, body: body}} ->
        {:reply, {:error, %{code: 400, body: Poison.decode!(body)}}, state}
    end
  end

  def handle_call(:get_balance, _from, state) do
    headers = [
      {"Authorization", "Bearer #{state.token}"},
      {"Ocp-Apim-Subscription-Key", state.subscription_key},
      {"X-Target-Environment", "sandbox"}
    ]
    case DisbursementClient.get_balance(headers) do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} -> {:reply, Poison.decode!(body), state}
      {:ok, %HTTPoison.Response{body: body, status_code: 404}} -> {:reply, {:error, Poison.decode!(body)}, state}
      {:ok, %HTTPoison.Response{body: body, status_code: 500}} -> {:reply, {:error, Poison.decode!(body)}, state}
      {:ok, %HTTPoison.Response{body: body, status_code: 503}} -> {:reply, {:error, Poison.decode!(body)}, state}
    end
  end

  def handle_call({:get_transaction_status, reference_id}, _from, state) do
    headers = [
      {"Authorization", "Bearer #{state.token}"},
      {"Ocp-Apim-Subscription-Key", state.subscription_key},
      {"X-Target-Environment", "sandbox"},
      {"X-Reference-Id", reference_id},
    ]
    case DisbursementClient.get_transaction_status(reference_id, headers) do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} -> {:reply, Poison.decode!(body), state}
    end
  end

  defp reference_id do
    UUID.uuid4()
  end
end