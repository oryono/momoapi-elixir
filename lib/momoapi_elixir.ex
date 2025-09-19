defmodule MomoapiElixir do
  @moduledoc """
  MTN Mobile Money API client for Elixir.

  This library provides a functional interface to interact with MTN's Mobile Money API,
  supporting both Collections (payments from consumers) and Disbursements (transfers to payees).

  ## Quick Start

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

      {:ok, reference_id} = MomoapiElixir.Collections.request_to_pay(config, payment)

      # Disbursements - Transfer money to payee
      transfer = %{
        amount: "50",
        currency: "UGX",
        externalId: "transfer_456",
        payee: %{
          partyIdType: "MSISDN",
          partyId: "256784123456"
        }
      }

      {:ok, reference_id} = MomoapiElixir.Disbursements.transfer(config, transfer)

  ## Modules

  - `MomoapiElixir.Collections` - Collections API functions
  - `MomoapiElixir.Disbursements` - Disbursements API functions
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

  This is a convenience function that delegates to `MomoapiElixir.Collections.request_to_pay/2`.
  """
  @spec request_to_pay(config(), map()) :: {:ok, String.t()} | {:error, term()}
  def request_to_pay(config, body) do
    Collections.request_to_pay(config, body)
  end

  @doc """
  Transfer money to a payee (Disbursements API).

  This is a convenience function that delegates to `MomoapiElixir.Disbursements.transfer/2`.
  """
  @spec transfer(config(), map()) :: {:ok, String.t()} | {:error, term()}
  def transfer(config, body) do
    Disbursements.transfer(config, body)
  end

  @doc """
  Get Collections account balance.

  This is a convenience function that delegates to `MomoapiElixir.Collections.get_balance/1`.
  """
  @spec get_collections_balance(config()) :: {:ok, map()} | {:error, term()}
  def get_collections_balance(config) do
    Collections.get_balance(config)
  end

  @doc """
  Get Disbursements account balance.

  This is a convenience function that delegates to `MomoapiElixir.Disbursements.get_balance/1`.
  """
  @spec get_disbursements_balance(config()) :: {:ok, map()} | {:error, term()}
  def get_disbursements_balance(config) do
    Disbursements.get_balance(config)
  end
end
