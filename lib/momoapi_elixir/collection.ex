defmodule Collection do
  use GenServer

  @base_url Application.get_env(:momoapi_elixir, :base_url)
  @party_types ["msisdn", "email", "party_code"]


  defmodule Option do
    @base_url_o Application.get_env(:momoapi_elixir, :base_url)
    defstruct user_id: nil, primary_key: nil, api_key: nil, call_back_url: nil, base_url: @base_url_o
  end

  def start_link(%{api_key: api_key, primary_key: primary_key, user_id: user_id}) do
    GenServer.start_link(
      __MODULE__,
      %Option{api_key: api_key, primary_key: primary_key, user_id: user_id},
      name: :collections
    )
  end

  def init(state) do
    state = Map.put(state, :token, nil)
    {:ok, state}
  end

  def get_token do
    GenServer.call(:collections, :get_token)
  end

  def set_token do
    GenServer.cast(:collections, :set_token)
  end

  @doc """
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


  def request_to_pay(
        %{
          amount: _body,
          currency: _currency,
          externalId: _external_id,
          payer: %{
            partyIdType: _party_type,
            partyId: _party_id
          },
          payerMessage: _payer_message,
          payeeNote: _payee_note
        } = body
      ) do
    GenServer.call(:collections, {:request_to_pay, body})
  end

  def get_balance do
    GenServer.call(:collections, :get_balance)
  end

  def get_transaction_status(reference_id) do
    GenServer.call(:collections, {:get_transaction_status, reference_id})
  end

  def get_party_status(id, type) when type in @party_types do
    GenServer.call(:collections, {:get_party_status, id, type})
  end

  def handle_call(:get_token, _from, state) do
    token = Map.get(state, :token)
    {:reply, {:ok, token}, state}
  end


  def handle_call({:request_to_pay, body}, _from, state) do
    reference_id = UUID.uuid4()
    headers = [
      {"Authorization", "Bearer #{state.token}"},
      {"Ocp-Apim-Subscription-Key", state.primary_key},
      {"X-Reference-Id", reference_id},
      {"X-Target-Environment", "sandbox"}
    ]
    body_encoded = Poison.encode!(body)

    case HTTPoison.post(@base_url <> "/collection/v1_0/requesttopay", body_encoded, headers) do
      {:ok, %HTTPoison.Response{status_code: 202, body: _body}} -> {:reply, {:ok, reference_id}, state}
    end

  end

  def handle_call({:get_transaction_status, reference_id}, _from, state) do
    headers = [
      {"Authorization", "Bearer #{state.token}"},
      {"Ocp-Apim-Subscription-Key", state.primary_key},
      {"X-Target-Environment", "sandbox"}
    ]
    case HTTPoison.get(@base_url <> "/collection/v1_0/requesttopay/#{reference_id}", headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:reply, {:ok, Map.get(Poison.decode!(body), "status")}, state}
    end
  end

  def handle_call(:get_balance, _from, state) do
    headers = [
      {"Authorization", "Bearer #{state.token}"},
      {"Ocp-Apim-Subscription-Key", state.primary_key},
      {"X-Target-Environment", "sandbox"}
    ]

    case HTTPoison.get(@base_url <> "/collection/v1_0/account/balance", headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} -> {:reply, {:ok, Poison.decode!(body)}, state}
    end
  end

  def handle_call({:get_party_status, id, type}, _from, state) do
    headers = [
      {"Authorization", "Bearer #{state.token}"},
      {"Ocp-Apim-Subscription-Key", state.primary_key},
      {"X-Target-Environment", "sandbox"}
    ]
    case HTTPoison.get(@base_url <> "/collection/v1_0/accountholder/#{type}/#{id}/active", headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} -> {:reply, {:ok, Poison.decode!(body)}, state}
    end
  end

  def handle_cast(:set_token, state) do
    encoded_string = Base.encode64(
      state.user_id <>
      ":" <> state.api_key
    )

    headers = [
      {"Authorization", "Basic #{encoded_string}"},
      {"Ocp-Apim-Subscription-Key", "#{state.primary_key}"}
    ]
    case HTTPoison.post(@base_url <> "/collection/token/", [], headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        %{"access_token" => access_token} = Poison.decode!(body)
        state = %{state | token: access_token}
        {:noreply, state}
    end
  end
end
