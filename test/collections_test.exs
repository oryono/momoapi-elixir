defmodule MomoapiElixir.CollectionsTest do
  use ExUnit.Case, async: true
  import Mox

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  describe "Collections" do
    test "makes the correct request" do
      reference_id = UUID.uuid4()
      body = %{
        amount: "10",
        currency: "EUR",
        externalId: "123456",
        payer: %{
          partyIdType: "MSISDN",
          partyId: "46733123450"
        },
        payerMessage: "testing",
        payeeNote: "hello"
      }
      CollectionMock
      |> expect(:post, fn _url, _body, _headers -> reference_id end)
      response = MomoapiElixir.Collection.CollectionClient.request_to_pay(body, [])
      assert reference_id == response
    end

    test "raises an error when the amount is missing" do
      body = %{
        amount: "",
        currency: "EUR",
        externalId: "123456",
        payer: %{
          partyIdType: "MSISDN",
          partyId: "46733123450"
        },
        payerMessage: "testing",
        payeeNote: "hello"
      }

      assert_raise RuntimeError, "Amount is required", fn ->
        MomoapiElixir.Collection.CollectionClient.request_to_pay(body, [])
      end
    end

    test "raises an error when the currency is missing" do
      body = %{
        amount: "10",
        currency: "",
        externalId: "123456",
        payer: %{
          partyIdType: "MSISDN",
          partyId: "46733123450"
        },
        payerMessage: "testing",
        payeeNote: "hello"
      }

      assert_raise RuntimeError, "Currency is required", fn ->
        MomoapiElixir.Collection.CollectionClient.request_to_pay(body, [])
      end
    end

    test "raises an error when the party id is missing" do
      body = %{
        amount: "10",
        currency: "EUR",
        externalId: "123456",
        payer: %{
          partyIdType: "MSISDN",
          partyId: ""
        },
        payerMessage: "testing",
        payeeNote: "hello"
      }
      assert_raise RuntimeError, "Party id is required", fn ->
        MomoapiElixir.Collection.CollectionClient.request_to_pay(body, [])
      end
    end

    test "raises an error when the party id type is missing" do
      body = %{
        amount: "10",
        currency: "EUR",
        externalId: "123456",
        payer: %{
          partyIdType: "",
          partyId: "256784275529"
        },
        payerMessage: "testing",
        payeeNote: "hello"
      }
      assert_raise RuntimeError, "Party id type is required", fn ->
        MomoapiElixir.Collection.CollectionClient.request_to_pay(body, [])
      end
    end

    test "raises an error when the body is empty" do
      assert_raise RuntimeError, "Body is empty", fn ->
        MomoapiElixir.Collection.CollectionClient.request_to_pay(%{}, [])
      end
    end

    test "test makes correct request to get balance" do
      CollectionMock
      |> expect(:get, fn _url, _headers -> %{"availableBalance" => "25", "currency" => "EUR"} end)

      response = MomoapiElixir.Collection.CollectionClient.get_balance([])
      assert response == %{"availableBalance" => "25", "currency" => "EUR"}
    end

    test "test makes correct request to get transaction status" do
      reference_id = UUID.uuid4()
      expected_response = %{
        "amount" => "10",
        "currency" => "EUR",
        "externalId" => "123456",
        "payeeNote" => "hello",
        "payer" => %{
          "partyId" => "46733123450",
          "partyIdType" => "MSISDN"
        },
        "payerMessage" => "testing",
        "reason" => "INTERNAL_PROCESSING_ERROR",
        "status" => "FAILED"
      }

      CollectionMock
      |> expect(
           :get,
           fn _url, _headers -> expected_response
           end
         )
      response = MomoapiElixir.Collection.CollectionClient.get_transaction_status(reference_id, [])
      assert expected_response == response
    end
  end
end