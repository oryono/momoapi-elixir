defmodule MomoapiElixir.CollectionsTest do
  use ExUnit.Case, async: true
  import Mox

  alias MomoapiElixir.Collections

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  @valid_config %{
    subscription_key: "test_subscription_key",
    user_id: "test_user_id",
    api_key: "test_api_key",
    target_environment: "sandbox"
  }

  @valid_payment %{
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

  describe "request_to_pay/2" do
    test "returns reference_id on successful payment request" do
      # Mock auth token request
      ClientMock
      |> expect(:post, fn "/collection/token/", _body, _headers ->
        {:ok, %{status_code: 200, body: "{\"access_token\": \"test_token\"}"}}
      end)

      # Mock payment request
      ClientMock
      |> expect(:post, fn "/collection/v1_0/requesttopay", _body, headers ->
        # Verify headers are correct
        assert {"Authorization", "Bearer test_token"} in headers
        assert {"Ocp-Apim-Subscription-Key", "test_subscription_key"} in headers
        assert {"X-Target-Environment", "sandbox"} in headers

        # Check that X-Reference-Id is present
        reference_id_header = Enum.find(headers, fn {key, _} -> key == "X-Reference-Id" end)
        assert reference_id_header != nil

        {:ok, %{status_code: 202, body: ""}}
      end)

      result = Collections.request_to_pay(@valid_config, @valid_payment)

      assert {:ok, reference_id} = result
      assert is_binary(reference_id)
      assert String.length(reference_id) > 0
    end

    test "returns error on validation failure" do
      invalid_payment = %{
        amount: "",  # Invalid: empty amount
        currency: "USD",
        externalId: "123"
        # Missing required payer field
      }

      result = Collections.request_to_pay(@valid_config, invalid_payment)

      assert {:error, validation_errors} = result
      assert is_list(validation_errors)

      # Should have errors for amount and payer
      error_fields = Enum.map(validation_errors, & &1.field)
      assert :amount in error_fields
      assert :payer in error_fields
    end

    test "returns error on auth failure" do
      ClientMock
      |> expect(:post, fn "/collection/token/", _body, _headers ->
        {:ok, %{status_code: 401, body: "{\"error\": \"unauthorized\"}"}}
      end)

      result = Collections.request_to_pay(@valid_config, @valid_payment)

      assert {:error, {:auth_failed, 401, %{"error" => "unauthorized"}}} = result
    end

    test "returns error on payment request failure" do
      # Mock successful auth
      ClientMock
      |> expect(:post, fn "/collection/token/", _body, _headers ->
        {:ok, %{status_code: 200, body: "{\"access_token\": \"test_token\"}"}}
      end)

      # Mock failed payment request
      ClientMock
      |> expect(:post, fn "/collection/v1_0/requesttopay", _body, _headers ->
        {:ok, %{status_code: 400, body: "{\"error\": \"bad_request\"}"}}
      end)

      result = Collections.request_to_pay(@valid_config, @valid_payment)

      assert {:error, %{status_code: 400, body: %{"error" => "bad_request"}}} = result
    end
  end

  describe "get_balance/1" do
    test "returns balance on success" do
      expected_balance = %{"availableBalance" => "1000", "currency" => "UGX"}

      # Mock auth
      ClientMock
      |> expect(:post, fn "/collection/token/", _body, _headers ->
        {:ok, %{status_code: 200, body: "{\"access_token\": \"test_token\"}"}}
      end)

      # Mock balance request
      ClientMock
      |> expect(:get, fn "/collection/v1_0/account/balance", headers ->
        assert {"Authorization", "Bearer test_token"} in headers
        {:ok, %{status_code: 200, body: Poison.encode!(expected_balance)}}
      end)

      result = Collections.get_balance(@valid_config)

      assert {:ok, ^expected_balance} = result
    end

    test "returns error on failure" do
      # Mock auth
      ClientMock
      |> expect(:post, fn "/collection/token/", _body, _headers ->
        {:ok, %{status_code: 200, body: "{\"access_token\": \"test_token\"}"}}
      end)

      # Mock failed balance request
      ClientMock
      |> expect(:get, fn "/collection/v1_0/account/balance", _headers ->
        {:ok, %{status_code: 404, body: "{\"error\": \"not_found\"}"}}
      end)

      result = Collections.get_balance(@valid_config)

      assert {:error, %{status_code: 404, body: %{"error" => "not_found"}}} = result
    end
  end

  describe "get_transaction_status/2" do
    test "returns transaction data on success" do
      reference_id = UUID.uuid4()
      expected_transaction = %{
        "amount" => "100",
        "currency" => "UGX",
        "status" => "SUCCESSFUL"
      }

      # Mock auth
      ClientMock
      |> expect(:post, fn "/collection/token/", _body, _headers ->
        {:ok, %{status_code: 200, body: "{\"access_token\": \"test_token\"}"}}
      end)

      # Mock transaction status request
      ClientMock
      |> expect(:get, fn "/collection/v1_0/requesttopay/" <> ^reference_id, headers ->
        assert {"Authorization", "Bearer test_token"} in headers
        assert {"X-Reference-Id", ^reference_id} in headers
        {:ok, %{status_code: 200, body: Poison.encode!(expected_transaction)}}
      end)

      result = Collections.get_transaction_status(@valid_config, reference_id)

      assert {:ok, ^expected_transaction} = result
    end
  end
end