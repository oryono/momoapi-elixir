defmodule MomoapiElixir.Validator do

  def validate_collections(
         %{
           amount: amount
         }
       ) when is_nil(amount) or amount == "" do
    raise "Amount is required"
  end

  def validate_collections(
         %{
           currency: currency
         }
       ) when is_nil(currency) or currency == "" do
    raise "Currency is required"
  end

  def validate_collections(
         %{
           payer: %{
             partyId: party_id
           },
         }
       ) when is_nil(party_id) or party_id == "" do
    raise "Party id is required"
  end

  def validate_collections(
        %{
          payer: %{
            partyIdType: party_id_type
          },
        }
      ) when is_nil(party_id_type) or party_id_type == "" do
    raise "Party id type is required"
  end

  def validate_collections(body) when body == %{} do
    raise "Body is empty"
  end

  def validate_collections(body) do
    body
  end
end