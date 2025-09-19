defmodule Mix.Tasks.Provision do
  use Mix.Task

  @base_url Application.compile_env(:momoapi_elixir, :base_url, "https://sandbox.momodeveloper.mtn.com")

  @shortdoc "Creates the user id and user api key."
  def run([subscription_key, webhook_host]) do
    HTTPoison.start()

    reference_id = reference_id()

    case HTTPoison.post(
           @base_url <> "/v1_0/apiuser",
           "{\"providerCallbackHost\": \"#{webhook_host}\"}",
           [
             {"X-Reference-Id", reference_id},
             {"Ocp-Apim-Subscription-Key", subscription_key}
           ]
         ) do
      {:ok, response} when response.status_code == 409 ->
        Mix.shell().info("Duplicate reference id")

      {:ok, response} when response.status_code == 201 ->
        case HTTPoison.post(
               @base_url <> "/v1_0/apiuser/#{reference_id}/apikey",
               [],
               [
                 {"Ocp-Apim-Subscription-Key", subscription_key}
               ]
             ) do
          {:ok, key_response} when key_response.status_code == 201 ->
            {:ok, %{"apiKey" => api_key}} = Poison.decode(key_response.body)
            Mix.shell().info("Your user id is #{reference_id} and your API key is #{api_key}")
        end

      {:ok, _} ->
        Mix.shell().info("An unknown error was encountered")
    end
  end

  def run([_subscription_key]) do
    raise "One of the arguments has not been provided. Please provide subscription key for arg 1 and callback for arg 2"
  end

  def run([]) do
    raise "Both subscription_key and callback host are required"
  end

  defp reference_id do
    UUID.uuid4()
  end
end
