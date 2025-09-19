# Momoapi Elixir
Power your Elixir applications with the momoapi_elixir library

### Installation
Add the package to your project

```elixir
def deps do
  [
    {:momoapi_elixir, "~> 0.1.0"}
  ]
end
```

### Sandbox credentials
Next, we need to get the User ID and Api key and to do this we shall need to use the Primary Key for the Product to which we are subscribed, as well as specify a host. We run the `mix provision` as below, with the subscription key as the first argument and callback host as second argument

```
mix provision subscription_key callback
```

If all goes well, it will print the credentials on the terminal as shown below
```
Your user id is 8bf4101b-ee3a-4eb1-968d-73dfc94e4011 and your API key is 6d18ef492b364d52974d1e0ae5319a40

```

### Configuration

The library supports multiple ways to configure your MTN MoMo API credentials:

#### Option 1: Environment Variables (Recommended for Production)

Set these environment variables:

```bash
export MOMO_SUBSCRIPTION_KEY="your_subscription_key"
export MOMO_USER_ID="your_user_id"
export MOMO_API_KEY="your_api_key"
export MOMO_TARGET_ENVIRONMENT="production"  # or "sandbox"
```

Then use in your code:

```elixir
# Automatically loads from environment variables
{:ok, config} = MomoapiElixir.Config.from_env()

# Use with Collections API
{:ok, reference_id} = MomoapiElixir.Collections.request_to_pay(config, payment_body)
```

#### Option 2: Manual Configuration

```elixir
# Create configuration manually
config = %{
  subscription_key: "your_subscription_key",
  user_id: "your_user_id",
  api_key: "your_api_key",
  target_environment: "sandbox"  # or "production"
}

# Use with Collections API
{:ok, reference_id} = MomoapiElixir.Collections.request_to_pay(config, payment_body)
```

### Collections

#### Functions
- `request_to_pay(body)` This operation is used to request a payment from a consumer (Payer). The payer will be asked to authorize the payment. The transaction is executed once the payer has authorized the payment. The transaction will be in status PENDING until it is authorized or declined by the payer, or it is timed out by the system. Status of the transaction can be validated by using get_transaction_status

- `get_transaction_status(reference_id)` Retrieve transaction information using the reference_id returned by request_to_pay. You can invoke it at intervals until the transaction fails or succeeds.

- `get_balance` Get the balance of the account.

#### Sample Code
```elixir
defmodule MomoTest.Deposit do
  alias MomoapiElixir.Collection
  alias MomoapiElixir.Collection.Option

  def initiate do
    config = %Option{
      subscription_key: "some_subscription_key",
      user_id: "some_user_id",
      api_key: "some_api_key"
    }
    Collection.start(config)
  end

  def test_collections do
    body =   %{
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
    Collection.request_to_pay(body)
  end

  def test_get_transaction_status(reference_id) do
    Collection.get_transaction_status(reference_id)
  end

  def test_get_balance() do
    Collection.get_balance
  end
end
```

### Disbursements
The Disbursements' api can be started with the following parameters. Note that the user id and api key for production are provided on the MTN OVA dashboard;

- `subscription_key`: Primary Key for the Collections product.
- `user_id`: For sandbox, use the one generated with the `mix provision` command.
- `api_key`: For sandbox, use the one generated with the `mix provision` command.

```elixir
alias MomoapiElixir.Disbursement
alias MomoapiElixir.Disbursement.Option
# Create options. Subscription key, user id and api key are required
options = %Option{
  subscription_key: "some_key",
  user_id: "some_user_id",
  api_key: "some_api_key",
}

Disbursement.start(options)
```

#### Functions
- `transfer(body)` Used to transfer an amount from the owner’s account to a payee account. It returns a transaction id which can use to check the transaction status with the getTransaction function

- `get_transaction_status(reference_id)` Retrieve transaction information using the reference_id returned by transfer. You can invoke it at intervals until the transaction fails or succeeds.

- `get_balance` Get your account balance.

#### Sample Code
```elixir
defmodule MomoTest.Withdraw do
  alias MomoapiElixir.Disbursement
  alias MomoapiElixir.Disbursement.Option

  def initiate do
    config = %Option{
      subscription_key: "some_subscription_key",
      user_id: "some_user_id",
      api_key: "some_api_key"
    }
    Disbursement.start(config)
  end

  def test_disbursements do
    body =   %{
      amount: "50",
      currency: "EUR",
      externalId: "123456",
      payee: %{
        partyIdType: "MSISDN",
        partyId: "46733123450"
      },
    }
    Disbursement.transfer(body)
  end

  def test_get_transaction_status(reference_id) do
    Disbursement.get_transaction_status(reference_id)
  end

  def test_get_balance() do
    Disbursement.get_balance
  end
end
```
