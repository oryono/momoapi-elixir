defmodule MomoapiElixir.DisbursementsTest do
  use ExUnit.Case, async: true
  import Mox

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  describe "Disbursements" do
    test "makes the correct request" do
      reference_id = UUID.uuid4()
      body = %{
        amount: "10",
        currency: "EUR",
        externalId: "947354",
        payee: %{
          partyIdType: "MSISDN",
          partyId: "+256776564739"
        },
        payerMessage: "testing",
        payeeNote: "hello"
      }
      ClientMock
      |> expect(:post, fn _url, _body, _headers -> reference_id end)
      response = MomoapiElixir.Disbursement.DisbursementClient.transfer(body, [])
      assert reference_id == response
    end

    test "raises an error when the amount is missing" do
      body = %{
        amount: "",
        currency: "EUR",
        externalId: "947354",
        payee: %{
          partyIdType: "MSISDN",
          partyId: "+256776564739"
        },
        payerMessage: "testing",
        payeeNote: "hello"
      }

      assert_raise RuntimeError, "Amount is required", fn ->
        MomoapiElixir.Disbursement.DisbursementClient.transfer(body, [])
      end
    end

    test "raises an error when the currency is missing" do
      body = %{
        amount: "10",
        currency: "",
        externalId: "947354",
        payee: %{
          partyIdType: "MSISDN",
          partyId: "+256776564739"
        },
        payerMessage: "testing",
        payeeNote: "hello"
      }

      assert_raise RuntimeError, "Currency is required", fn ->
        MomoapiElixir.Disbursement.DisbursementClient.transfer(body, [])
      end
    end

    test "raises an error when the party id is missing" do
      body = %{
        amount: "10",
        currency: "EUR",
        externalId: "123456",
        payee: %{
          partyIdType: "MSISDN",
          partyId: ""
        },
        payerMessage: "testing",
        payeeNote: "hello"
      }
      assert_raise RuntimeError, "Party id is required", fn ->
        MomoapiElixir.Disbursement.DisbursementClient.transfer(body, [])
      end
    end


    test "raises an error when the party id type is missing" do
      body = %{
        amount: "10",
        currency: "EUR",
        externalId: "123456",
        payee: %{
          partyIdType: "",
          partyId: "256784275529"
        },
        payerMessage: "testing",
        payeeNote: "hello"
      }
      assert_raise RuntimeError, "Party id type is required", fn ->
        MomoapiElixir.Disbursement.DisbursementClient.transfer(body, [])
      end
    end

    test "raises an error when the body is empty" do
      assert_raise RuntimeError, "Body is empty", fn ->
        MomoapiElixir.Disbursement.DisbursementClient.transfer(%{}, [])
      end
    end

    test "test makes correct request to get balance" do
      ClientMock
      |> expect(:get, fn _url, _headers -> %{"availableBalance" => "25", "currency" => "EUR"} end)

      response = MomoapiElixir.Disbursement.DisbursementClient.get_balance([])
      assert response == %{"availableBalance" => "25", "currency" => "EUR"}
    end

    test "test makes correct request to get transaction status" do
      reference_id = UUID.uuid4()
      expected_response = %{
        "amount" => "10",
        "currency" => "EUR",
        "externalId" => "123456",
        "payeeNote" => "hello",
        "payee" => %{
          "partyId" => "46733123450",
          "partyIdType" => "MSISDN"
        },
        "payerMessage" => "testing",
        "reason" => "INTERNAL_PROCESSING_ERROR",
        "status" => "FAILED"
      }

      ClientMock
      |> expect(
           :get,
           fn _url, _headers -> expected_response
           end
         )
      response = MomoapiElixir.Disbursement.DisbursementClient.get_transaction_status(reference_id, [])
      assert expected_response == response
    end
  end
end