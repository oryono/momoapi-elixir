defmodule Client do
  @base_url "https://sandbox.momodeveloper.mtn.com"

  @reference_id UUID.uuid4()

  def run do
    headers = [
      {"X-Reference-Id", @reference_id},
      {"Ocp-Apim-Subscription-Key", "1a9040e705d54d678f024ff0e4dede22"}
    ]

    body = "{\"providerCallbackHost\": \"clinic.com\"}"

    case HTTPoison.post(@base_url <> "/v1_0/apiuser", body, headers) do
      {:ok, %HTTPoison.Response{status_code: 409}} ->
        {:error, "Duplicated reference id"}

      {:ok, %HTTPoison.Response{status_code: 201}} ->
        case HTTPoison.post(@base_url <> "/v1_0/apiuser/#{@reference_id}/apikey", [], headers) do
          {:ok, %HTTPoison.Response{status_code: 201, body: body}} ->
            IO.inspect(body)
        end
    end
  end
end
