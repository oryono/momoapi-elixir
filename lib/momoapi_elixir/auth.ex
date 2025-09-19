defmodule MomoapiElixir.Auth do
  @moduledoc """
  Authentication module for MTN Mobile Money API.

  Handles token generation for both Collections and Disbursements APIs.
  """

  @client Application.compile_env(:momoapi_elixir, :http_client, MomoapiElixir.Client)

  @type config :: %{
    subscription_key: String.t(),
    user_id: String.t(),
    api_key: String.t()
  }

  @type service :: :collections | :disbursements

  @doc """
  Get an access token for the specified service.

  ## Examples

      iex> config = %{subscription_key: "key", user_id: "user", api_key: "api"}
      iex> MomoapiElixir.Auth.get_token(:collections, config)
      {:ok, "access_token_string"}
  """
  @spec get_token(service(), config()) :: {:ok, String.t()} | {:error, term()}
  def get_token(:collections, config) do
    authorize_service("/collection/token/", config)
  end

  def get_token(:disbursements, config) do
    authorize_service("/disbursement/token/", config)
  end

  # Private functions

  defp authorize_service(endpoint, %{subscription_key: subscription_key} = config) do
    basic_auth_token = create_basic_auth_token(config)
    headers = [
      {"Authorization", "Basic #{basic_auth_token}"},
      {"Ocp-Apim-Subscription-Key", subscription_key}
    ]

    case @client.post(endpoint, %{}, headers) do
      {:ok, %{status_code: 200, body: body}} ->
        case decode_token_response(body) do
          {:ok, token} -> {:ok, token}
          {:error, reason} -> {:error, {:token_decode_error, reason}}
        end

      {:ok, %{status_code: status_code, body: body}} ->
        {:error, {:auth_failed, status_code, decode_body(body)}}

      {:error, reason} ->
        {:error, {:http_error, reason}}
    end
  end

  defp create_basic_auth_token(%{user_id: user_id, api_key: api_key}) do
    Base.encode64("#{user_id}:#{api_key}")
  end

  defp decode_token_response(body) when is_binary(body) do
    case Poison.decode(body) do
      {:ok, %{"access_token" => access_token}} when is_binary(access_token) ->
        {:ok, access_token}
      {:ok, response} ->
        {:error, {:missing_access_token, response}}
      {:error, reason} ->
        {:error, {:json_decode_error, reason}}
    end
  end

  defp decode_token_response(body) do
    {:error, {:invalid_response_format, body}}
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