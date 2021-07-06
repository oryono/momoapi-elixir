#defmodule MomoapiElixir.Validation do
#  def validate_collections(body) do
#    body
#  end
#
#  def validate_collections(
#        %{
#          amount: amount,
#          currency: _,
#          externalId: _,
#          payer: %{
#            partyIdType: _,
#            partyId: _
#          },
#          payerMessage: _,
#          payeeNote: _
#        } = body
#      ) when amount == nil do
#    raise "Amount is required"
#  end
#
#  def validate_collections(
#        %{
#          amount: _,
#          currency: currency,
#          externalId: _,
#          payer: %{
#            partyIdType: _,
#            partyId: _
#          },
#          payerMessage: _,
#          payeeNote: _
#        } = body
#      ) when amount == nil do
#    raise "Currency is required"
#  end
#
#  def validate_collections(
#        %{
#          amount: _,
#          currency: _,
#          externalId: _,
#          payer: %{
#            partyIdType: _,
#            partyId: party_id
#          },
#          payerMessage: _,
#          payeeNote: _
#        } = body
#      ) when amount == nil do
#    raise "Party id is required"
#  end
#end