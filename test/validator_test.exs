defmodule MomoapiElixir.ValidatorTest do
  use ExUnit.Case, async: true

  alias MomoapiElixir.Validator

  describe "validate_collections/1" do
    test "validates successful collections request" do
      valid_request = %{
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

      assert {:ok, ^valid_request} = Validator.validate_collections(valid_request)
    end

    test "returns error for empty body" do
      assert {:error, [error]} = Validator.validate_collections(%{})
      assert error.field == :body
      assert error.message == "Request body cannot be empty"
    end

    test "returns error for missing required fields" do
      invalid_request = %{
        currency: "UGX"
        # Missing amount, externalId, payer
      }

      assert {:error, errors} = Validator.validate_collections(invalid_request)
      error_fields = Enum.map(errors, & &1.field)

      assert :amount in error_fields
      assert :externalId in error_fields
      assert :payer in error_fields
    end

    test "returns error for empty required fields" do
      invalid_request = %{
        amount: "",
        currency: "",
        externalId: "",
        payer: %{}
      }

      assert {:error, errors} = Validator.validate_collections(invalid_request)
      error_fields = Enum.map(errors, & &1.field)

      assert :amount in error_fields
      assert :currency in error_fields
      assert :externalId in error_fields
    end

    test "validates amount format and positivity" do
      # Test invalid amount formats
      invalid_amounts = ["0", "-10", "abc", "10.5.5", ""]

      for invalid_amount <- invalid_amounts do
        request = %{
          amount: invalid_amount,
          currency: "UGX",
          externalId: "123",
          payer: %{partyIdType: "MSISDN", partyId: "256784123456"}
        }

        assert {:error, errors} = Validator.validate_collections(request)
        assert Enum.any?(errors, &(&1.field == :amount))
      end

      # Test valid amounts
      valid_amounts = ["1", "100", "1000.50", "0.01"]

      for valid_amount <- valid_amounts do
        request = %{
          amount: valid_amount,
          currency: "UGX",
          externalId: "123",
          payer: %{partyIdType: "MSISDN", partyId: "256784123456"}
        }

        assert {:ok, _} = Validator.validate_collections(request)
      end
    end

    test "validates currency format" do
      # Invalid currencies
      invalid_currencies = ["ug", "UGXX", "123", "ugx"]

      for invalid_currency <- invalid_currencies do
        request = %{
          amount: "100",
          currency: invalid_currency,
          externalId: "123",
          payer: %{partyIdType: "MSISDN", partyId: "256784123456"}
        }

        assert {:error, errors} = Validator.validate_collections(request)
        assert Enum.any?(errors, &(&1.field == :currency))
      end

      # Valid currencies
      valid_currencies = ["UGX", "EUR", "USD"]

      for valid_currency <- valid_currencies do
        request = %{
          amount: "100",
          currency: valid_currency,
          externalId: "123",
          payer: %{partyIdType: "MSISDN", partyId: "256784123456"}
        }

        assert {:ok, _} = Validator.validate_collections(request)
      end
    end

    test "validates payer details" do
      # Missing payer fields
      request_missing_party_id = %{
        amount: "100",
        currency: "UGX",
        externalId: "123",
        payer: %{partyIdType: "MSISDN"}
      }

      assert {:error, errors} = Validator.validate_collections(request_missing_party_id)
      assert Enum.any?(errors, &(&1.field == :"payer.partyId"))

      # Invalid party ID type
      request_invalid_type = %{
        amount: "100",
        currency: "UGX",
        externalId: "123",
        payer: %{partyIdType: "INVALID", partyId: "123456789"}
      }

      assert {:error, errors} = Validator.validate_collections(request_invalid_type)
      assert Enum.any?(errors, &(&1.field == :"payer.partyIdType"))

      # Invalid MSISDN format
      request_invalid_msisdn = %{
        amount: "100",
        currency: "UGX",
        externalId: "123",
        payer: %{partyIdType: "MSISDN", partyId: "abc"}
      }

      assert {:error, errors} = Validator.validate_collections(request_invalid_msisdn)
      assert Enum.any?(errors, &(&1.field == :"payer.partyId"))

      # Valid MSISDN formats
      valid_msisdns = ["256784123456", "+256784123456", "46733123450"]

      for msisdn <- valid_msisdns do
        request = %{
          amount: "100",
          currency: "UGX",
          externalId: "123",
          payer: %{partyIdType: "MSISDN", partyId: msisdn}
        }

        assert {:ok, _} = Validator.validate_collections(request)
      end
    end

    test "validates message length" do
      long_message = String.duplicate("a", 161)

      request_long_payer_message = %{
        amount: "100",
        currency: "UGX",
        externalId: "123",
        payer: %{partyIdType: "MSISDN", partyId: "256784123456"},
        payerMessage: long_message
      }

      assert {:error, errors} = Validator.validate_collections(request_long_payer_message)
      assert Enum.any?(errors, &(&1.field == :payerMessage))

      request_long_payee_note = %{
        amount: "100",
        currency: "UGX",
        externalId: "123",
        payer: %{partyIdType: "MSISDN", partyId: "256784123456"},
        payeeNote: long_message
      }

      assert {:error, errors} = Validator.validate_collections(request_long_payee_note)
      assert Enum.any?(errors, &(&1.field == :payeeNote))
    end

    test "validates email format for payer" do
      # Invalid email
      request_invalid_email = %{
        amount: "100",
        currency: "UGX",
        externalId: "123",
        payer: %{partyIdType: "EMAIL", partyId: "invalid-email"}
      }

      assert {:error, errors} = Validator.validate_collections(request_invalid_email)
      assert Enum.any?(errors, &(&1.field == :"payer.partyId"))

      # Valid email
      request_valid_email = %{
        amount: "100",
        currency: "UGX",
        externalId: "123",
        payer: %{partyIdType: "EMAIL", partyId: "user@example.com"}
      }

      assert {:ok, _} = Validator.validate_collections(request_valid_email)
    end
  end

  describe "validate_disbursements/1" do
    test "validates successful disbursements request" do
      valid_request = %{
        amount: "50",
        currency: "UGX",
        externalId: "transfer_456",
        payee: %{
          partyIdType: "MSISDN",
          partyId: "256784123456"
        }
      }

      assert {:ok, ^valid_request} = Validator.validate_disbursements(valid_request)
    end

    test "returns error for missing payee field" do
      invalid_request = %{
        amount: "50",
        currency: "UGX",
        externalId: "transfer_456"
        # Missing payee
      }

      assert {:error, errors} = Validator.validate_disbursements(invalid_request)
      error_fields = Enum.map(errors, & &1.field)
      assert :payee in error_fields
    end

    test "validates payee details similar to payer" do
      # Invalid payee party ID type
      request_invalid_type = %{
        amount: "50",
        currency: "UGX",
        externalId: "transfer_456",
        payee: %{partyIdType: "INVALID", partyId: "123456789"}
      }

      assert {:error, errors} = Validator.validate_disbursements(request_invalid_type)
      assert Enum.any?(errors, &(&1.field == :"payee.partyIdType"))

      # Valid payee with EMAIL
      request_valid_email = %{
        amount: "50",
        currency: "UGX",
        externalId: "transfer_456",
        payee: %{partyIdType: "EMAIL", partyId: "recipient@example.com"}
      }

      assert {:ok, _} = Validator.validate_disbursements(request_valid_email)
    end

    test "handles PARTY_CODE type gracefully" do
      request_party_code = %{
        amount: "50",
        currency: "UGX",
        externalId: "transfer_456",
        payee: %{partyIdType: "PARTY_CODE", partyId: "SOME_CODE_123"}
      }

      assert {:ok, _} = Validator.validate_disbursements(request_party_code)
    end
  end

  describe "error structure" do
    test "returns structured errors with field, message, and value" do
      invalid_request = %{
        amount: "invalid",
        currency: "xyz"
      }

      assert {:error, errors} = Validator.validate_collections(invalid_request)

      for error <- errors do
        assert Map.has_key?(error, :field)
        assert Map.has_key?(error, :message)
        assert Map.has_key?(error, :value)
        assert is_atom(error.field)
        assert is_binary(error.message)
      end
    end
  end
end