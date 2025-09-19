defmodule MomoapiElixir.Collections do
  @moduledoc """
  Collections API for MTN Mobile Money.

  This module provides functions to request payments from consumers,
  check transaction status, and get account balance.
  """

  alias MomoapiElixir.{Auth, Validator}

  @client Application.compile_env(:momoapi_elixir, :http_client, MomoapiElixir.Client)

  @type config :: %{
    subscription_key: String.t(),
    user_id: String.t(),
    api_key: String.t(),
    target_environment: String.t()
  }

  @type payment_request :: %{
    amount: String.t(),
    currency: String.t(),
    externalId: String.t(),
    payer: %{
      partyIdType: String.t(),
      partyId: String.t()
    },
    payerMessage: String.t(),
    payeeNote: String.t()
  }

  @doc """
  Request a payment from a consumer (Payer).

  The payer will be asked to authorize the payment. The transaction will be
  executed once the payer has authorized the payment.

  ## Examples

      iex> config = %{subscription_key: "key", user_id: "user", api_key: "api", target_environment: "sandbox"}
      iex> payment = %{amount: "100", currency: "UGX", externalId: "123", payer: %{partyIdType: "MSISDN", partyId: "256784123456"}, payerMessage: "Payment", payeeNote: "Note"}
      iex> MomoapiElixir.Collections.request_to_pay(config, payment)
      {:ok, "reference-id-uuid"}
  """
  @spec request_to_pay(config(), payment_request()) :: {:ok, String.t()} | {:error, term()}
  def request_to_pay(config, body) do
    with {:ok, validated_body} <- Validator.validate_collections(body),
         {:ok, token} <- Auth.get_token(:collections, config),
         {:ok, reference_id} <- generate_reference_id(),
         headers <- build_headers(token, config, reference_id),
         {:ok, response} <- @client.post("/collection/v1_0/requesttopay", validated_body, headers) do
      handle_payment_response(response, reference_id)
    end
  end

  @doc """
  Get the balance of the account.

  ## Examples

      iex> config = %{subscription_key: "key", user_id: "user", api_key: "api", target_environment: "sandbox"}
      iex> MomoapiElixir.Collections.get_balance(config)
      {:ok, %{"availableBalance" => "1000", "currency" => "UGX"}}
  """
  @spec get_balance(config()) :: {:ok, map()} | {:error, term()}
  def get_balance(config) do
    with {:ok, token} <- Auth.get_token(:collections, config),
         headers <- build_headers(token, config),
         {:ok, response} <- @client.get("/collection/v1_0/account/balance", headers) do
      handle_balance_response(response)
    end
  end

  @doc """
  Retrieve transaction information using the reference ID.

  You can invoke this at intervals until the transaction fails or succeeds.

  ## Examples

      iex> config = %{subscription_key: "key", user_id: "user", api_key: "api", target_environment: "sandbox"}
      iex> MomoapiElixir.Collections.get_transaction_status(config, "ref-id")
      {:ok, %{"status" => "SUCCESSFUL", "amount" => "100"}}
  """
  @spec get_transaction_status(config(), String.t()) :: {:ok, map()} | {:error, term()}
  def get_transaction_status(config, reference_id) do
    with {:ok, token} <- Auth.get_token(:collections, config),
         headers <- build_headers(token, config, reference_id),
         {:ok, response} <- @client.get("/collection/v1_0/requesttopay/#{reference_id}", headers) do
      handle_transaction_response(response)
    end
  end

  # Private functions

  defp generate_reference_id do
    {:ok, UUID.uuid4()}
  end

  defp build_headers(token, config, reference_id \\ nil) do
    base_headers = [
      {"Authorization", "Bearer #{token}"},
      {"Ocp-Apim-Subscription-Key", config.subscription_key},
      {"X-Target-Environment", config.target_environment || "sandbox"}
    ]

    case reference_id do
      nil -> base_headers
      id -> [{"X-Reference-Id", id} | base_headers]
    end
  end

  defp handle_payment_response({:ok, %{status_code: 202}}, reference_id) do
    {:ok, reference_id}
  end

  defp handle_payment_response({:ok, %{status_code: status_code, body: body}}, _reference_id) do
    {:error, %{status_code: status_code, body: decode_body(body)}}
  end

  defp handle_payment_response({:error, reason}, _reference_id) do
    {:error, reason}
  end

  defp handle_balance_response({:ok, %{status_code: 200, body: body}}) do
    {:ok, decode_body(body)}
  end

  defp handle_balance_response({:ok, %{status_code: status_code, body: body}}) do
    {:error, %{status_code: status_code, body: decode_body(body)}}
  end

  defp handle_balance_response({:error, reason}) do
    {:error, reason}
  end

  defp handle_transaction_response({:ok, %{status_code: 200, body: body}}) do
    {:ok, decode_body(body)}
  end

  defp handle_transaction_response({:ok, %{status_code: status_code, body: body}}) do
    {:error, %{status_code: status_code, body: decode_body(body)}}
  end

  defp handle_transaction_response({:error, reason}) do
    {:error, reason}
  end

  defp decode_body(""), do: %{}
  defp decode_body(body) when is_binary(body) do
    case Poison.decode(body) do
      {:ok, decoded} -> decoded
      {:error, _} -> body
    end
  end
  defp decode_body(body), do: body
end