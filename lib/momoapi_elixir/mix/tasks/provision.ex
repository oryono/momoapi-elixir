defmodule Mix.Tasks.Provision do
  use Mix.Task

#  @reference_id UUID.uuid4()
  @base_url "https://sandbox.momodeveloper.mtn.com"

  @shortdoc "Creates the user id and user api key."
  def run(_) do
    HTTPoison.start()

    reference_id = reference_id()

    case HTTPoison.post(
           @base_url <> "/v1_0/apiuser",
           "{\"providerCallbackHost\": \"clinic.com\"}",
           [
             {"X-Reference-Id", reference_id},
             {"Ocp-Apim-Subscription-Key", "1a9040e705d54d678f024ff0e4dede22"}
           ]
         ) do
      {:ok, %HTTPoison.Response{status_code: 409}} ->
        Mix.shell().info("Duplicate reference id")

      {:ok, %HTTPoison.Response{status_code: 201}} ->
        case HTTPoison.post(
               @base_url <> "/v1_0/apiuser/#{reference_id}/apikey",
               [],
               [
                 {"Ocp-Apim-Subscription-Key", "1a9040e705d54d678f024ff0e4dede22"}
               ]
             ) do
          {:ok, %HTTPoison.Response{status_code: 201, body: body}} ->
            {:ok, %{"apiKey" => api_key}} = Poison.decode(body)
            Mix.shell().info("Your user id id #{reference_id} and your API key is #{api_key}")
        end

      {:ok, _} ->
        Mix.shell().info("An unknown error was encountered")
    end
  end

  defp reference_id do
    UUID.uuid4()
  end
end
