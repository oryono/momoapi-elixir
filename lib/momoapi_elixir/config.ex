defmodule MomoapiElixir.Config do
  @moduledoc """
  Configuration helpers for MTN Mobile Money API.

  Provides utilities to build configuration from environment variables
  and application config for secure credential management.
  """

  @type config :: %{
    subscription_key: String.t(),
    user_id: String.t(),
    api_key: String.t(),
    target_environment: String.t()
  }

  @doc """
  Build configuration from environment variables.

  Reads the following environment variables:
  - `MOMO_SUBSCRIPTION_KEY` - Your MTN MoMo subscription key
  - `MOMO_USER_ID` - Your MTN MoMo user ID
  - `MOMO_API_KEY` - Your MTN MoMo API key
  - `MOMO_TARGET_ENVIRONMENT` - "sandbox" or "production" (defaults to application config)

  ## Examples

      # Set environment variables first:
      # export MOMO_SUBSCRIPTION_KEY="your_subscription_key"
      # export MOMO_USER_ID="your_user_id"
      # export MOMO_API_KEY="your_api_key"
      # export MOMO_TARGET_ENVIRONMENT="production"

      iex> MomoapiElixir.Config.from_env()
      {:ok, %{
        subscription_key: "your_subscription_key",
        user_id: "your_user_id",
        api_key: "your_api_key",
        target_environment: "production"
      }}

      # If environment variables are missing:
      iex> MomoapiElixir.Config.from_env()
      {:error, {:missing_env_vars, [:subscription_key, :user_id]}}
  """
  @spec from_env() :: {:ok, config()} | {:error, {:missing_env_vars, [atom()]}}
  def from_env do
    env_vars = %{
      subscription_key: System.get_env("MOMO_SUBSCRIPTION_KEY"),
      user_id: System.get_env("MOMO_USER_ID"),
      api_key: System.get_env("MOMO_API_KEY"),
      target_environment: System.get_env("MOMO_TARGET_ENVIRONMENT")
    }

    # Use application config as fallback for target_environment
    target_environment = env_vars.target_environment ||
                        Application.get_env(:momoapi_elixir, :target_environment, "sandbox")

    config = %{
      subscription_key: env_vars.subscription_key,
      user_id: env_vars.user_id,
      api_key: env_vars.api_key,
      target_environment: target_environment
    }

    case validate_config(config) do
      {:ok, config} -> {:ok, config}
      {:error, missing} -> {:error, {:missing_env_vars, missing}}
    end
  end

  @doc """
  Build configuration from application config.

  Reads from your application's configuration files.

  ## Examples

      # In config/prod.exs:
      config :momoapi_elixir,
        subscription_key: "your_subscription_key",
        user_id: "your_user_id",
        api_key: "your_api_key",
        target_environment: "production"

      iex> MomoapiElixir.Config.from_app_config()
      {:ok, %{
        subscription_key: "your_subscription_key",
        user_id: "your_user_id",
        api_key: "your_api_key",
        target_environment: "production"
      }}
  """
  @spec from_app_config() :: {:ok, config()} | {:error, {:missing_config, [atom()]}}
  def from_app_config do
    config = %{
      subscription_key: Application.get_env(:momoapi_elixir, :subscription_key),
      user_id: Application.get_env(:momoapi_elixir, :user_id),
      api_key: Application.get_env(:momoapi_elixir, :api_key),
      target_environment: Application.get_env(:momoapi_elixir, :target_environment, "sandbox")
    }

    case validate_config(config) do
      {:ok, config} -> {:ok, config}
      {:error, missing} -> {:error, {:missing_config, missing}}
    end
  end

  @doc """
  Create configuration manually.

  ## Examples

      iex> MomoapiElixir.Config.new("sub_key", "user_id", "api_key", "production")
      {:ok, %{
        subscription_key: "sub_key",
        user_id: "user_id",
        api_key: "api_key",
        target_environment: "production"
      }}
  """
  @spec new(String.t(), String.t(), String.t(), String.t()) :: {:ok, config()}
  def new(subscription_key, user_id, api_key, target_environment \\ "sandbox") do
    {:ok, %{
      subscription_key: subscription_key,
      user_id: user_id,
      api_key: api_key,
      target_environment: target_environment
    }}
  end

  # Private functions

  defp validate_config(config) do
    required_fields = [:subscription_key, :user_id, :api_key]
    missing_fields = Enum.filter(required_fields, fn field ->
      value = Map.get(config, field)
      is_nil(value) or value == ""
    end)

    case missing_fields do
      [] -> {:ok, config}
      missing -> {:error, missing}
    end
  end
end