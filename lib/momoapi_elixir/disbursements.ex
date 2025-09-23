defmodule MomoapiElixir.Disbursements do
  @moduledoc """
  Disbursements API for MTN Mobile Money.

  This module provides functions to transfer money to payees,
  check transaction status, and get account balance.
  """

  alias MomoapiElixir.{Auth, Client, Validator}

  @type config :: %{
    subscription_key: String.t(),
    user_id: String.t(),
    api_key: String.t(),
    target_environment: String.t()
  }

  @type transfer_request :: %{
    amount: String.t(),
    currency: String.t(),
    externalId: String.t(),
    payee: %{
      partyIdType: String.t(),
      partyId: String.t()
    },
    payerMessage: String.t(),
    payeeNote: String.t()
  }

  @doc """
  Transfer money to a payee account.

  Used to transfer an amount from the owner's account to a payee account.
  Returns a reference ID which can be used to check the transaction status.

  ## Examples

      iex> config = %{subscription_key: "key", user_id: "user", api_key: "api", target_environment: "sandbox"}
      iex> transfer = %{amount: "100", currency: "UGX", externalId: "123", payee: %{partyIdType: "MSISDN", partyId: "256784123456"}}
      iex> MomoapiElixir.Disbursements.transfer(config, transfer)
      {:ok, "reference-id-uuid"}
  """
  @spec transfer(config(), transfer_request()) :: {:ok, String.t()} | {:error, term()}
  def transfer(config, body) do
    with {:ok, validated_body} <- Validator.validate_disbursements(body),
         {:ok, token} <- Auth.get_token(:disbursements, config),
         {:ok, reference_id} <- generate_reference_id(),
         headers <- build_headers(token, config, reference_id),
         {:ok, response} <- Client.post("/disbursement/v1_0/transfer", validated_body, headers) do
      handle_transfer_response(response, reference_id)
    end
  end

  @doc """
  Get the balance of the disbursements account.

  ## Examples

      iex> config = %{subscription_key: "key", user_id: "user", api_key: "api", target_environment: "sandbox"}
      iex> MomoapiElixir.Disbursements.get_balance(config)
      {:ok, %{"availableBalance" => "1000", "currency" => "UGX"}}
  """
  @spec get_balance(config()) :: {:ok, map()} | {:error, term()}
  def get_balance(config) do
    with {:ok, token} <- Auth.get_token(:disbursements, config),
         headers <- build_headers(token, config),
         {:ok, response} <- Client.get("/disbursement/v1_0/account/balance", headers) do
      handle_balance_response(response)
    end
  end

  @doc """
  Retrieve transaction information using the reference ID.

  You can invoke this at intervals until the transaction fails or succeeds.

  ## Examples

      iex> config = %{subscription_key: "key", user_id: "user", api_key: "api", target_environment: "sandbox"}
      iex> MomoapiElixir.Disbursements.get_transaction_status(config, "ref-id")
      {:ok, %{"status" => "SUCCESSFUL", "amount" => "100"}}
  """
  @spec get_transaction_status(config(), String.t()) :: {:ok, map()} | {:error, term()}
  def get_transaction_status(config, reference_id) do
    with {:ok, token} <- Auth.get_token(:disbursements, config),
         headers <- build_headers(token, config, reference_id),
         {:ok, response} <- Client.get("/disbursement/v1_0/transfer/#{reference_id}", headers) do
      handle_transaction_response(response)
    end
  end

  # Private functions

  defp generate_reference_id do
    {:ok, UUID.uuid4()}
  end

  defp build_headers(token, config, reference_id \\ nil) do
    target_env = Map.get(config, :target_environment, "sandbox")
    base_headers = [
      {"Authorization", "Bearer #{token}"},
      {"Ocp-Apim-Subscription-Key", Map.get(config, :subscription_key)},
      {"X-Target-Environment", target_env}
    ]

    case reference_id do
      nil -> base_headers
      id -> [{"X-Reference-Id", id} | base_headers]
    end
  end

  defp handle_transfer_response(%{status_code: 202}, reference_id) do
    {:ok, reference_id}
  end

  defp handle_transfer_response(%{status_code: status_code, body: body}, _reference_id) do
    {:error, %{status_code: status_code, body: decode_body(body)}}
  end

  defp handle_balance_response(%{status_code: 200, body: body}) do
    {:ok, decode_body(body)}
  end

  defp handle_balance_response(%{status_code: status_code, body: body}) do
    {:error, %{status_code: status_code, body: decode_body(body)}}
  end

  defp handle_transaction_response(%{status_code: 200, body: body}) do
    {:ok, decode_body(body)}
  end

  defp handle_transaction_response(%{status_code: status_code, body: body}) do
    {:error, %{status_code: status_code, body: decode_body(body)}}
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