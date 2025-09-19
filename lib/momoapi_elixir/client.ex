defmodule MomoapiElixir.Client do
  @moduledoc """
  HTTP client for MTN Mobile Money API.

  Handles all HTTP communication with the MTN MoMo API endpoints.
  """

  @behaviour MomoapiElixir.ClientBehaviour

  @base_url Application.compile_env(:momoapi_elixir, :base_url, "https://sandbox.momodeveloper.mtn.com")

  @type headers :: [{String.t(), String.t()}]
  @type response :: %{status_code: integer(), body: String.t(), headers: headers()}

  @doc """
  Make a POST request to the API.

  ## Examples

      iex> MomoapiElixir.Client.post("/collection/token/", %{}, [{"Content-Type", "application/json"}])
      {:ok, %{status_code: 200, body: "{...}", headers: [...]}}
  """
  @spec post(String.t(), map(), headers()) :: {:ok, response()} | {:error, term()}
  def post(path, body, headers) do
    url = build_url(path)
    encoded_body = encode_body(body)
    full_headers = add_default_headers(headers)

    case HTTPoison.post(url, encoded_body, full_headers) do
      {:ok, response} ->
        {:ok, %{status_code: response.status_code, body: response.body, headers: response.headers}}
      {:error, error} ->
        {:error, {:http_error, error.reason}}
    end
  end

  @doc """
  Make a GET request to the API.

  ## Examples

      iex> MomoapiElixir.Client.get("/collection/v1_0/account/balance", [{"Authorization", "Bearer token"}])
      {:ok, %{status_code: 200, body: "{...}", headers: [...]}}
  """
  @spec get(String.t(), headers()) :: {:ok, response()} | {:error, term()}
  def get(path, headers) do
    url = build_url(path)
    full_headers = add_default_headers(headers)

    case HTTPoison.get(url, full_headers) do
      {:ok, response} ->
        {:ok, %{status_code: response.status_code, body: response.body, headers: response.headers}}
      {:error, error} ->
        {:error, {:http_error, error.reason}}
    end
  end

  # Private functions

  defp build_url(path) do
    @base_url <> path
  end

  defp encode_body(body) when is_map(body) do
    Poison.encode!(body)
  end

  defp encode_body(body) when is_binary(body) do
    body
  end

  defp add_default_headers(headers) do
    default_headers = [
      {"Content-Type", "application/json"},
      {"Accept", "application/json"}
    ]

    Enum.uniq_by(headers ++ default_headers, fn {key, _} -> key end)
  end
end