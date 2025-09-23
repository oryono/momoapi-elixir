defmodule MomoapiElixir do
  @moduledoc """
  MTN Mobile Money API client for Elixir.

  This library provides a functional interface to interact with MTN's Mobile Money API,
  supporting both Collections (payments from consumers) and Disbursements (transfers to payees).

  ## Quick Start

  Set up configuration and handle responses properly:

      # Option 1: Use environment variables (Recommended for production)
      {:ok, config} = MomoapiElixir.Config.from_env()

      # Option 2: Manual configuration
      config = %{
        subscription_key: "your_subscription_key",
        user_id: "your_user_id",
        api_key: "your_api_key",
        target_environment: "sandbox" # or "production"
      }

      # Collections - Request payment from consumer
      payment = %{
        amount: "100",
        currency: "UGX",
        externalId: "payment_123",
        payer: %{
          partyIdType: "MSISDN",
          partyId: "256784123456"
        },
        payerMessage: "Payment for goods",
        payeeNote: "Thank you"
      }

      # Proper error handling with case pattern matching
      case MomoapiElixir.Collections.request_to_pay(config, payment) do
        {:ok, reference_id} ->
          # Payment initiated successfully
          reference_id
        {:error, reason} ->
          # Handle error appropriately
          reason
      end

  ## Main Functions

  This module provides convenient wrapper functions for the most common operations:

  ### Collections (Payments from consumers)
  - `request_to_pay/2` - Request payment from a consumer
  - `get_payment_status/2` - Check payment transaction status
  - `get_collections_balance/1` - Get Collections account balance

  ### Disbursements (Transfers to payees)
  - `transfer/2` - Transfer money to a payee
  - `get_transfer_status/2` - Check transfer transaction status
  - `get_disbursements_balance/1` - Get Disbursements account balance

  ## Core Modules

  - `MomoapiElixir.Collections` - Collections API functions
  - `MomoapiElixir.Disbursements` - Disbursements API functions
  - `MomoapiElixir.Config` - Configuration management
  - `MomoapiElixir.Auth` - Authentication utilities
  - `MomoapiElixir.Validator` - Request validation utilities
  """

  # Convenience aliases for the main APIs
  alias MomoapiElixir.{Collections, Disbursements}

  @type config :: %{
    subscription_key: String.t(),
    user_id: String.t(),
    api_key: String.t(),
    target_environment: String.t()
  }

  @doc """
  Request a payment from a consumer (Collections API).

  The payer will be asked to authorize the payment. The transaction will be
  executed once the payer has authorized the payment. Returns a reference ID
  that can be used to check the transaction status.

  ## Parameters

  - `config` - Configuration map with subscription_key, user_id, api_key, and target_environment
  - `body` - Payment request map with the following required fields:
    - `amount` - Payment amount as string (e.g., "100")
    - `currency` - ISO 4217 currency code (e.g., "UGX")
    - `externalId` - Your unique transaction identifier
    - `payer` - Map with `partyIdType` ("MSISDN" or "EMAIL") and `partyId`
    - `payerMessage` - Message shown to the payer (optional)
    - `payeeNote` - Internal note for the payee (optional)

  ## Examples

      config = %{
        subscription_key: "your_key",
        user_id: "your_user_id",
        api_key: "your_api_key",
        target_environment: "sandbox"
      }

      payment = %{
        amount: "1000",
        currency: "UGX",
        externalId: "payment_123",
        payer: %{
          partyIdType: "MSISDN",
          partyId: "256784123456"
        },
        payerMessage: "Payment for goods",
        payeeNote: "Thank you"
      }

      case MomoapiElixir.request_to_pay(config, payment) do
        {:ok, reference_id} ->
          IO.puts("Payment initiated: \#{reference_id}")
        {:error, validation_errors} when is_list(validation_errors) ->
          IO.puts("Validation failed: \#{inspect(validation_errors)}")
        {:error, %{status_code: status, body: body}} ->
          IO.puts("API error \#{status}: \#{inspect(body)}")
        {:error, reason} ->
          IO.puts("Request failed: \#{inspect(reason)}")
      end

  This is a convenience function that delegates to `MomoapiElixir.Collections.request_to_pay/2`.
  """
  @spec request_to_pay(config(), map()) :: {:ok, String.t()} | {:error, term()}
  def request_to_pay(config, body) do
    Collections.request_to_pay(config, body)
  end

  @doc """
  Transfer money to a payee (Disbursements API).

  Used to transfer an amount from the owner's account to a payee account.
  Returns a reference ID which can be used to check the transaction status.

  ## Parameters

  - `config` - Configuration map with subscription_key, user_id, api_key, and target_environment
  - `body` - Transfer request map with the following required fields:
    - `amount` - Transfer amount as string (e.g., "50")
    - `currency` - ISO 4217 currency code (e.g., "UGX")
    - `externalId` - Your unique transaction identifier
    - `payee` - Map with `partyIdType` ("MSISDN" or "EMAIL") and `partyId`
    - `payerMessage` - Message for the transfer (optional)
    - `payeeNote` - Note for the payee (optional)

  ## Examples

      config = %{
        subscription_key: "your_key",
        user_id: "your_user_id",
        api_key: "your_api_key",
        target_environment: "sandbox"
      }

      transfer = %{
        amount: "2500",
        currency: "UGX",
        externalId: "transfer_456",
        payee: %{
          partyIdType: "MSISDN",
          partyId: "256784987654"
        },
        payerMessage: "Salary payment",
        payeeNote: "Monthly salary"
      }

      case MomoapiElixir.transfer(config, transfer) do
        {:ok, reference_id} ->
          IO.puts("Transfer initiated: \#{reference_id}")
        {:error, validation_errors} when is_list(validation_errors) ->
          IO.puts("Validation failed: \#{inspect(validation_errors)}")
        {:error, %{status_code: status, body: body}} ->
          IO.puts("API error \#{status}: \#{inspect(body)}")
        {:error, reason} ->
          IO.puts("Transfer failed: \#{inspect(reason)}")
      end

  This is a convenience function that delegates to `MomoapiElixir.Disbursements.transfer/2`.
  """
  @spec transfer(config(), map()) :: {:ok, String.t()} | {:error, term()}
  def transfer(config, body) do
    Disbursements.transfer(config, body)
  end

  @doc """
  Get Collections account balance.

  Retrieves the current available balance for the Collections account.
  Useful for checking available funds before requesting payments.

  ## Parameters

  - `config` - Configuration map with subscription_key, user_id, api_key, and target_environment

  ## Examples

      config = %{
        subscription_key: "your_key",
        user_id: "your_user_id",
        api_key: "your_api_key",
        target_environment: "sandbox"
      }

      case MomoapiElixir.get_collections_balance(config) do
        {:ok, %{"availableBalance" => balance, "currency" => currency}} ->
          IO.puts("Collections balance: \#{balance} \#{currency}")
        {:error, %{status_code: status, body: body}} ->
          IO.puts("Failed to get balance: \#{status} - \#{inspect(body)}")
        {:error, reason} ->
          IO.puts("Request failed: \#{inspect(reason)}")
      end

  This is a convenience function that delegates to `MomoapiElixir.Collections.get_balance/1`.
  """
  @spec get_collections_balance(config()) :: {:ok, map()} | {:error, term()}
  def get_collections_balance(config) do
    Collections.get_balance(config)
  end

  @doc """
  Get Disbursements account balance.

  Retrieves the current available balance for the Disbursements account.
  Useful for checking available funds before initiating transfers.

  ## Parameters

  - `config` - Configuration map with subscription_key, user_id, api_key, and target_environment

  ## Examples

      config = %{
        subscription_key: "your_key",
        user_id: "your_user_id",
        api_key: "your_api_key",
        target_environment: "sandbox"
      }

      case MomoapiElixir.get_disbursements_balance(config) do
        {:ok, %{"availableBalance" => balance, "currency" => currency}} ->
          IO.puts("Disbursements balance: \#{balance} \#{currency}")
        {:error, %{status_code: 401}} ->
          IO.puts("Authentication failed - check your credentials")
        {:error, %{status_code: status, body: body}} ->
          IO.puts("Failed to get balance: \#{status} - \#{inspect(body)}")
        {:error, reason} ->
          IO.puts("Request failed: \#{inspect(reason)}")
      end

  This is a convenience function that delegates to `MomoapiElixir.Disbursements.get_balance/1`.
  """
  @spec get_disbursements_balance(config()) :: {:ok, map()} | {:error, term()}
  def get_disbursements_balance(config) do
    Disbursements.get_balance(config)
  end

  @doc """
  Get Collections transaction status.

  Retrieve transaction information using the reference ID returned from `request_to_pay/2`.
  You can invoke this at intervals until the transaction fails or succeeds.

  ## Parameters

  - `config` - Configuration map with subscription_key, user_id, api_key, and target_environment
  - `reference_id` - The reference ID returned from the payment request

  ## Examples

      config = %{
        subscription_key: "your_key",
        user_id: "your_user_id",
        api_key: "your_api_key",
        target_environment: "sandbox"
      }

      case MomoapiElixir.get_payment_status(config, reference_id) do
        {:ok, %{"status" => "SUCCESSFUL", "amount" => amount}} ->
          IO.puts("Payment of \#{amount} completed successfully!")
        {:ok, %{"status" => "PENDING"}} ->
          IO.puts("Payment is still processing...")
        {:ok, %{"status" => "FAILED", "reason" => reason}} ->
          IO.puts("Payment failed: \#{reason}")
        {:error, %{status_code: status, body: body}} ->
          IO.puts("Failed to get status: \#{status} - \#{inspect(body)}")
        {:error, reason} ->
          IO.puts("Request failed: \#{inspect(reason)}")
      end

  This is a convenience function that delegates to `MomoapiElixir.Collections.get_transaction_status/2`.
  """
  @spec get_payment_status(config(), String.t()) :: {:ok, map()} | {:error, term()}
  def get_payment_status(config, reference_id) do
    Collections.get_transaction_status(config, reference_id)
  end

  @doc """
  Get Disbursements transaction status.

  Retrieve transaction information using the reference ID returned from `transfer/2`.
  You can invoke this at intervals until the transaction fails or succeeds.

  ## Parameters

  - `config` - Configuration map with subscription_key, user_id, api_key, and target_environment
  - `reference_id` - The reference ID returned from the transfer request

  ## Examples

      config = %{
        subscription_key: "your_key",
        user_id: "your_user_id",
        api_key: "your_api_key",
        target_environment: "sandbox"
      }

      case MomoapiElixir.get_transfer_status(config, reference_id) do
        {:ok, %{"status" => "SUCCESSFUL", "amount" => amount, "externalId" => external_id}} ->
          IO.puts("Transfer \#{external_id} of \#{amount} completed successfully!")
        {:ok, %{"status" => "PENDING"}} ->
          IO.puts("Transfer is still processing...")
        {:ok, %{"status" => "FAILED", "reason" => reason}} ->
          IO.puts("Transfer failed: \#{reason}")
        {:error, %{status_code: status, body: body}} ->
          IO.puts("Failed to get status: \#{status} - \#{inspect(body)}")
        {:error, reason} ->
          IO.puts("Request failed: \#{inspect(reason)}")
      end

  This is a convenience function that delegates to `MomoapiElixir.Disbursements.get_transaction_status/2`.
  """
  @spec get_transfer_status(config(), String.t()) :: {:ok, map()} | {:error, term()}
  def get_transfer_status(config, reference_id) do
    Disbursements.get_transaction_status(config, reference_id)
  end
end
