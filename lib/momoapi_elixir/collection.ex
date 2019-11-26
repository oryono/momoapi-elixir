defmodule Collection do
  alias Client

  @base_url Application.get_env(:momoapi_elixir, :base_url)

  def token do
    encoded_string =
      Base.encode64(
        Application.get_env(:momoapi_elixir, :user_id) <>
          ":" <> Application.get_env(:momoapi_elixir, :api_key)
      )

    IO.inspect(encoded_string)

    headers = [
      {"Authorization", "Basic #{encoded_string}"},
      {"Ocp-Apim-Subscription-Key", "1a9040e705d54d678f024ff0e4dede22"}
    ]

    case HTTPoison.post(@base_url <> "/collection/token/", [], headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        %{"access_token" => access_token} = Poison.decode!(body)
        access_token
    end
  end

  def request_to_pay() do
    reference_id = UUID.uuid4()

    body = %{
      amount: "50",
      currency: "EUR",
      externalId: "123456",
      payer: %{
        partyIdType: "MSISDN",
        partyId: "256774290781"
      },
      payerMessage: "testing",
      payeeNote: "hello"
    }

    body_encoded = Poison.encode!(body)

    headers = [
      {"Authorization", "Bearer #{token}"},
      {"Ocp-Apim-Subscription-Key", "1a9040e705d54d678f024ff0e4dede22"},
      {"X-Reference-Id", reference_id},
      {"X-Target-Environment", "sandbox"}
    ]

    HTTPoison.post(@base_url <> "/collection/v1_0/requesttopay", body_encoded, headers)
  end

  def get_transaction(reference_id) do
    HTTPoison.get(@base_url <> "/collection/v1_0/requesttopay/#{reference_id}")
  end
end
