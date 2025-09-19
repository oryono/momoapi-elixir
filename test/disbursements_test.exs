defmodule MomoapiElixir.DisbursementsTest do
  use ExUnit.Case, async: true
  import Mox

  alias MomoapiElixir.Disbursements

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  @valid_config %{
    subscription_key: "test_subscription_key",
    user_id: "test_user_id",
    api_key: "test_api_key",
    target_environment: "sandbox"
  }

  @valid_transfer %{
    amount: "50",
    currency: "UGX",
    externalId: "transfer_456",
    payee: %{
      partyIdType: "MSISDN",
      partyId: "256784123456"
    },
    payerMessage: "Transfer payment",
    payeeNote: "Money transfer"
  }

  describe "transfer/2" do
    test "returns reference_id on successful transfer request" do
      # Mock auth token request
      ClientMock
      |> expect(:post, fn "/disbursement/token/", _body, _headers ->
        {:ok, %{status_code: 200, body: "{\"access_token\": \"test_token\"}"}}
      end)

      # Mock transfer request
      ClientMock
      |> expect(:post, fn "/disbursement/v1_0/transfer", _body, headers ->
        # Verify headers are correct
        assert {"Authorization", "Bearer test_token"} in headers
        assert {"Ocp-Apim-Subscription-Key", "test_subscription_key"} in headers
        assert {"X-Target-Environment", "sandbox"} in headers

        # Check that X-Reference-Id is present
        reference_id_header = Enum.find(headers, fn {key, _} -> key == "X-Reference-Id" end)
        assert reference_id_header != nil

        {:ok, %{status_code: 202, body: ""}}
      end)

      result = Disbursements.transfer(@valid_config, @valid_transfer)

      assert {:ok, reference_id} = result
      assert is_binary(reference_id)
      assert String.length(reference_id) > 0
    end

    test "returns error on validation failure" do
      invalid_transfer = %{
        amount: "0",  # Invalid: zero amount
        currency: "invalid",  # Invalid currency format
        externalId: "123"
        # Missing required payee field
      }

      result = Disbursements.transfer(@valid_config, invalid_transfer)

      assert {:error, validation_errors} = result
      assert is_list(validation_errors)

      # Should have errors for amount, currency, and payee
      error_fields = Enum.map(validation_errors, & &1.field)
      assert :amount in error_fields
      assert :currency in error_fields
      assert :payee in error_fields
    end

    test "returns error on auth failure" do
      ClientMock
      |> expect(:post, fn "/disbursement/token/", _body, _headers ->
        {:ok, %{status_code: 401, body: "{\"error\": \"unauthorized\"}"}}
      end)

      result = Disbursements.transfer(@valid_config, @valid_transfer)

      assert {:error, {:auth_failed, 401, %{"error" => "unauthorized"}}} = result
    end

    test "returns error on transfer request failure" do
      # Mock successful auth
      ClientMock
      |> expect(:post, fn "/disbursement/token/", _body, _headers ->
        {:ok, %{status_code: 200, body: "{\"access_token\": \"test_token\"}"}}
      end)

      # Mock failed transfer request
      ClientMock
      |> expect(:post, fn "/disbursement/v1_0/transfer", _body, _headers ->
        {:ok, %{status_code: 500, body: "{\"error\": \"internal_server_error\"}"}}
      end)

      result = Disbursements.transfer(@valid_config, @valid_transfer)

      assert {:error, %{status_code: 500, body: %{"error" => "internal_server_error"}}} = result
    end
  end

  describe "get_balance/1" do
    test "returns balance on success" do
      expected_balance = %{"availableBalance" => "5000", "currency" => "UGX"}

      # Mock auth
      ClientMock
      |> expect(:post, fn "/disbursement/token/", _body, _headers ->
        {:ok, %{status_code: 200, body: "{\"access_token\": \"test_token\"}"}}
      end)

      # Mock balance request
      ClientMock
      |> expect(:get, fn "/disbursement/v1_0/account/balance", headers ->
        assert {"Authorization", "Bearer test_token"} in headers
        {:ok, %{status_code: 200, body: Poison.encode!(expected_balance)}}
      end)

      result = Disbursements.get_balance(@valid_config)

      assert {:ok, ^expected_balance} = result
    end

    test "returns error on service unavailable" do
      # Mock auth
      ClientMock
      |> expect(:post, fn "/disbursement/token/", _body, _headers ->
        {:ok, %{status_code: 200, body: "{\"access_token\": \"test_token\"}"}}
      end)

      # Mock failed balance request
      ClientMock
      |> expect(:get, fn "/disbursement/v1_0/account/balance", _headers ->
        {:ok, %{status_code: 503, body: "{\"error\": \"service_unavailable\"}"}}
      end)

      result = Disbursements.get_balance(@valid_config)

      assert {:error, %{status_code: 503, body: %{"error" => "service_unavailable"}}} = result
    end
  end

  describe "get_transaction_status/2" do
    test "returns transaction data on success" do
      reference_id = UUID.uuid4()
      expected_transaction = %{
        "amount" => "50",
        "currency" => "UGX",
        "status" => "SUCCESSFUL",
        "externalId" => "transfer_456"
      }

      # Mock auth
      ClientMock
      |> expect(:post, fn "/disbursement/token/", _body, _headers ->
        {:ok, %{status_code: 200, body: "{\"access_token\": \"test_token\"}"}}
      end)

      # Mock transaction status request
      ClientMock
      |> expect(:get, fn "/disbursement/v1_0/transfer/" <> ^reference_id, headers ->
        assert {"Authorization", "Bearer test_token"} in headers
        assert {"X-Reference-Id", ^reference_id} in headers
        {:ok, %{status_code: 200, body: Poison.encode!(expected_transaction)}}
      end)

      result = Disbursements.get_transaction_status(@valid_config, reference_id)

      assert {:ok, ^expected_transaction} = result
    end
  end
end