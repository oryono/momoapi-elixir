# MTN MoMo API Elixir

[![Hex.pm](https://img.shields.io/hexpm/v/momoapi_elixir.svg)](https://hex.pm/packages/momoapi_elixir)
[![Documentation](https://img.shields.io/badge/documentation-hexdocs-blue.svg)](https://hexdocs.pm/momoapi_elixir)
[![License](https://img.shields.io/hexpm/l/momoapi_elixir.svg)](LICENSE)
[![Build Status](https://github.com/oryono/momoapi-elixir/workflows/CI/badge.svg)](https://github.com/oryono/momoapi-elixir/actions)

A comprehensive Elixir client library for the **MTN Mobile Money (MoMo) API**. Easily integrate mobile money payments, transfers, and account management into your Elixir applications.

## What is MTN Mobile Money?

MTN Mobile Money is a digital financial service that allows users to store, send, and receive money using their mobile phones. This library provides a simple interface to:

- 💳 **Collections** - Request payments and withdrawals from customers
- 💸 **Disbursements** - Send money and make deposits to recipients
- 👤 **Account Management** - Get user info, validate accounts, check balances
- 🔍 **Transaction Tracking** - Monitor transaction status and history
- 🔒 **Secure** - Production-ready with proper authentication
- 🌍 **Multi-environment** - Supports both sandbox and production

### ✨ New Features

This library now supports the **complete MTN Mobile Money API** including:

- **Withdrawal Requests** - Request money from customer accounts via Collections API
- **Direct Deposits** - Make instant deposits via Disbursements API
- **User Information** - Get basic user details for both Collections and Disbursements
- **Account Validation** - Check if accounts are active before transactions
- **Default Parameters** - MSISDN defaults for easier phone number handling
- **Enhanced Error Handling** - Proper Elixir error tuples instead of exceptions

## Quick Start

### 1. Installation

Add `momoapi_elixir` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:momoapi_elixir, "~> 0.1.1"}
  ]
end
```

### 2. Get Sandbox Credentials

For testing, generate sandbox credentials using the built-in Mix task:

```bash
mix provision YOUR_SUBSCRIPTION_KEY https://your-callback-url.com
```

This will output your sandbox `user_id` and `api_key`.

### 3. Configure Your Application

#### Option 1: Environment Variables (Recommended)

```bash
export MOMO_SUBSCRIPTION_KEY="your_subscription_key"
export MOMO_USER_ID="your_user_id"
export MOMO_API_KEY="your_api_key"
export MOMO_TARGET_ENVIRONMENT="sandbox"  # or "production"
```

#### Option 2: Application Configuration

```elixir
# config/config.exs
config :momoapi_elixir,
  subscription_key: "your_subscription_key",
  user_id: "your_user_id",
  api_key: "your_api_key",
  target_environment: "sandbox"
```

### 4. Make Your First Request

```elixir
# Load configuration
{:ok, config} = MomoapiElixir.Config.from_env()

# Request a payment
payment = %{
  amount: "1000",
  currency: "UGX",
  externalId: "payment_#{System.system_time()}",
  payer: %{
    partyIdType: "MSISDN",
    partyId: "256784123456"
  },
  payerMessage: "Payment for goods",
  payeeNote: "Thank you for your business"
}

case MomoapiElixir.Collections.request_to_pay(config, payment) do
  {:ok, reference_id} ->
    IO.puts("Payment initiated! Reference ID: #{reference_id}")
  {:error, reason} ->
    IO.puts("Payment failed: #{inspect(reason)}")
end
```

## API Reference

### Collections API

Request payments from customers, withdraw money, and manage account information.

#### Request Payment

```elixir
payment = %{
  amount: "5000",                    # Amount in string format
  currency: "UGX",                   # ISO 4217 currency code
  externalId: "unique_payment_id",   # Your unique transaction ID
  payer: %{
    partyIdType: "MSISDN",           # Phone number type
    partyId: "256784123456"          # Customer's phone number
  },
  payerMessage: "Payment description",
  payeeNote: "Internal note"
}

{:ok, reference_id} = MomoapiElixir.Collections.request_to_pay(config, payment)
```

#### Request Withdrawal

Request withdrawal from a consumer's account (requires user authorization):

```elixir
withdrawal = %{
  amount: "1000",
  currency: "UGX",
  externalId: "withdrawal_#{System.system_time()}",
  payer: %{
    partyIdType: "MSISDN",
    partyId: "256784123456"
  },
  payerMessage: "Cash withdrawal",
  payeeNote: "ATM withdrawal"
}

{:ok, reference_id} = MomoapiElixir.Collections.request_to_withdraw(config, withdrawal)
```

#### Check Transaction Status

```elixir
case MomoapiElixir.Collections.get_transaction_status(config, reference_id) do
  {:ok, %{"status" => "SUCCESSFUL", "amount" => amount}} ->
    IO.puts("Payment of #{amount} completed successfully!")

  {:ok, %{"status" => "PENDING"}} ->
    IO.puts("Payment is still processing...")

  {:ok, %{"status" => "FAILED", "reason" => reason}} ->
    IO.puts("Payment failed: #{reason}")

  {:error, reason} ->
    IO.puts("Error checking status: #{inspect(reason)}")
end
```

#### Get User Information

Get basic user information for account validation:

```elixir
# Using default MSISDN type
case MomoapiElixir.Collections.get_basic_user_info(config, "256784123456") do
  {:ok, %{"given_name" => first_name, "family_name" => last_name}} ->
    IO.puts("User: #{first_name} #{last_name}")
  {:error, %{status_code: 404}} ->
    IO.puts("User not found")
  {:error, reason} ->
    IO.puts("Error: #{inspect(reason)}")
end

# Explicitly specify account type
{:ok, user_info} = MomoapiElixir.Collections.get_basic_user_info(config, "EMAIL", "user@example.com")
```

#### Validate Account Status

Check if an account holder is active before initiating transactions:

```elixir
case MomoapiElixir.Collections.validate_account_holder_status(config, "256784123456") do
  {:ok, %{"result" => true}} ->
    IO.puts("Account is active and ready for transactions")
  {:ok, %{"result" => false}} ->
    IO.puts("Account is inactive")
  {:error, reason} ->
    IO.puts("Validation failed: #{inspect(reason)}")
end
```

#### Get Account Balance

```elixir
case MomoapiElixir.Collections.get_balance(config) do
  {:ok, %{"availableBalance" => balance, "currency" => currency}} ->
    IO.puts("Available balance: #{balance} #{currency}")
  {:error, reason} ->
    IO.puts("Error getting balance: #{inspect(reason)}")
end
```

### Disbursements API

Send money to recipients, make deposits, and manage account information.

#### Transfer Money

Send money to recipients (requires authorization from the recipient):

```elixir
transfer = %{
  amount: "2500",
  currency: "UGX",
  externalId: "transfer_#{System.system_time()}",
  payee: %{
    partyIdType: "MSISDN",
    partyId: "256784987654"
  },
  payerMessage: "Salary payment",
  payeeNote: "Monthly salary"
}

case MomoapiElixir.Disbursements.transfer(config, transfer) do
  {:ok, reference_id} ->
    IO.puts("Transfer initiated! Reference ID: #{reference_id}")
  {:error, reason} ->
    IO.puts("Transfer failed: #{inspect(reason)}")
end
```

#### Deposit Money

Direct deposit into a recipient's account (no authorization required):

```elixir
deposit = %{
  amount: "1500",
  currency: "UGX",
  externalId: "deposit_#{System.system_time()}",
  payee: %{
    partyIdType: "MSISDN",
    partyId: "256784987654"
  },
  payerMessage: "Bonus payment",
  payeeNote: "Performance bonus"
}

case MomoapiElixir.Disbursements.deposit(config, deposit) do
  {:ok, reference_id} ->
    IO.puts("Deposit completed! Reference ID: #{reference_id}")
  {:error, reason} ->
    IO.puts("Deposit failed: #{inspect(reason)}")
end
```

#### Check Transaction Status

```elixir
case MomoapiElixir.Disbursements.get_transaction_status(config, reference_id) do
  {:ok, %{"status" => "SUCCESSFUL", "amount" => amount}} ->
    IO.puts("Transaction of #{amount} completed successfully!")
  {:ok, %{"status" => "PENDING"}} ->
    IO.puts("Transaction is still processing...")
  {:error, reason} ->
    IO.puts("Error checking status: #{inspect(reason)}")
end
```

#### Get User Information (Disbursements)

Get basic user information via the Disbursements API:

```elixir
# Using default MSISDN type
case MomoapiElixir.Disbursements.get_basic_user_info(config, "256784987654") do
  {:ok, %{"given_name" => first_name, "family_name" => last_name}} ->
    IO.puts("Recipient: #{first_name} #{last_name}")
  {:error, reason} ->
    IO.puts("Error: #{inspect(reason)}")
end
```

#### Validate Account Status (Disbursements)

Check if a recipient account is active before making transfers:

```elixir
case MomoapiElixir.Disbursements.validate_account_holder_status(config, "256784987654") do
  {:ok, %{"result" => true}} ->
    IO.puts("Recipient account is active")
  {:ok, %{"result" => false}} ->
    IO.puts("Recipient account is inactive")
  {:error, reason} ->
    IO.puts("Validation failed: #{inspect(reason)}")
end
```

#### Get Disbursements Balance

```elixir
case MomoapiElixir.Disbursements.get_balance(config) do
  {:ok, %{"availableBalance" => balance, "currency" => currency}} ->
    IO.puts("Available balance: #{balance} #{currency}")
  {:error, reason} ->
    IO.puts("Error getting balance: #{inspect(reason)}")
end
```

## Configuration

### Environment-Specific Settings

The library automatically uses the correct API endpoints based on your environment:

- **Sandbox**: `https://sandbox.momodeveloper.mtn.com`
- **Production**: `https://momoapi.mtn.com`

### Configuration Options

```elixir
# All available configuration options
config = %{
  subscription_key: "your_subscription_key",  # Required
  user_id: "your_user_id",                   # Required
  api_key: "your_api_key",                   # Required
  target_environment: "sandbox"              # "sandbox" or "production"
}
```

### Loading Configuration

```elixir
# From environment variables
{:ok, config} = MomoapiElixir.Config.from_env()

# From application config
{:ok, config} = MomoapiElixir.Config.from_app_config()

# Manual configuration
{:ok, config} = MomoapiElixir.Config.new(
  "subscription_key",
  "user_id",
  "api_key",
  "sandbox"
)
```

## Error Handling

The library uses consistent error handling patterns:

### Validation Errors

```elixir
invalid_payment = %{
  amount: "0",           # Invalid: must be positive
  currency: "INVALID",   # Invalid: must be 3-letter ISO code
  # missing required fields
}

case MomoapiElixir.Collections.request_to_pay(config, invalid_payment) do
  {:ok, reference_id} ->
    # Success
  {:error, validation_errors} when is_list(validation_errors) ->
    # Multiple validation errors
    Enum.each(validation_errors, fn error ->
      IO.puts("Field #{error.field}: #{error.message}")
    end)
  {:error, reason} ->
    # Other errors (network, auth, etc.)
    IO.puts("Error: #{inspect(reason)}")
end
```

### Common Error Types

```elixir
case MomoapiElixir.Collections.request_to_pay(config, payment) do
  {:ok, reference_id} ->
    # Success case

  {:error, validation_errors} when is_list(validation_errors) ->
    # Validation failed - fix your request data

  {:error, {:auth_failed, status_code, body}} ->
    # Authentication failed - check credentials

  {:error, {:http_error, reason}} ->
    # Network error - retry or check connectivity

  {:error, %{status_code: 500}} ->
    # Server error - try again later

  {:error, reason} ->
    # Other errors
end
```

## Production Deployment

### 1. Get Production Credentials

1. Complete KYC requirements with MTN
2. Get production credentials from MTN OVA dashboard
3. Set environment variables:

```bash
export MOMO_SUBSCRIPTION_KEY="your_production_subscription_key"
export MOMO_USER_ID="your_production_user_id"
export MOMO_API_KEY="your_production_api_key"
export MOMO_TARGET_ENVIRONMENT="production"
```

### 2. Deploy Your Application

```bash
MIX_ENV=prod mix release
MIX_ENV=prod _build/prod/rel/your_app/bin/your_app start
```

The library will automatically use production endpoints when `target_environment` is set to `"production"`.

## Testing

This library includes comprehensive test coverage with proper mocking:

```bash
# Run tests
mix test

# Run with coverage
mix test --cover

# Run specific test file
mix test test/collections_test.exs
```

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup

```bash
git clone https://github.com/oryono/momoapi-elixir.git
cd momoapi-elixir
mix deps.get
mix test
```

### Reporting Issues

Please report bugs and feature requests on our [GitHub Issues](https://github.com/oryono/momoapi-elixir/issues) page.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and changes.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- 📖 **Documentation**: [HexDocs](https://hexdocs.pm/momoapi_elixir)
- 🐛 **Issues**: [GitHub Issues](https://github.com/oryono/momoapi-elixir/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/oryono/momoapi-elixir/discussions)

## Acknowledgments

- MTN Group for providing the Mobile Money API
- The Elixir community for excellent tooling and libraries

---

**Made with ❤️ for the Elixir community**