defmodule MomoapiElixir.Validator do
  @moduledoc """
  Validation module for MTN Mobile Money API requests.

  Provides comprehensive validation for collections and disbursements requests,
  returning structured error information instead of raising exceptions.
  """

  @type validation_error :: %{
    field: atom(),
    message: String.t(),
    value: any()
  }

  @type validation_result :: {:ok, map()} | {:error, [validation_error()]}

  @doc """
  Validate a collections payment request.

  ## Examples

      iex> valid_request = %{
      ...>   amount: "100",
      ...>   currency: "UGX",
      ...>   externalId: "123",
      ...>   payer: %{partyIdType: "MSISDN", partyId: "256784123456"},
      ...>   payerMessage: "Payment",
      ...>   payeeNote: "Note"
      ...> }
      iex> MomoapiElixir.Validator.validate_collections(valid_request)
      {:ok, %{amount: "100", currency: "UGX", ...}}

      iex> invalid_request = %{amount: "", currency: "UGX"}
      iex> MomoapiElixir.Validator.validate_collections(invalid_request)
      {:error, [%{field: :amount, message: "Amount is required", value: ""}]}
  """
  @spec validate_collections(map()) :: validation_result()
  def validate_collections(body) when body == %{} do
    {:error, [%{field: :body, message: "Request body cannot be empty", value: %{}}]}
  end

  def validate_collections(body) do
    []
    |> validate_required_fields(body, :collections)
    |> validate_amount(body)
    |> validate_currency(body)
    |> validate_external_id(body)
    |> validate_payer(body)
    |> validate_messages(body)
    |> return_validation_result(body)
  end

  @doc """
  Validate a disbursements transfer request.

  ## Examples

      iex> valid_request = %{
      ...>   amount: "100",
      ...>   currency: "UGX",
      ...>   externalId: "123",
      ...>   payee: %{partyIdType: "MSISDN", partyId: "256784123456"}
      ...> }
      iex> MomoapiElixir.Validator.validate_disbursements(valid_request)
      {:ok, %{amount: "100", currency: "UGX", ...}}
  """
  @spec validate_disbursements(map()) :: validation_result()
  def validate_disbursements(body) when body == %{} do
    {:error, [%{field: :body, message: "Request body cannot be empty", value: %{}}]}
  end

  def validate_disbursements(body) do
    []
    |> validate_required_fields(body, :disbursements)
    |> validate_amount(body)
    |> validate_currency(body)
    |> validate_external_id(body)
    |> validate_payee(body)
    |> validate_messages(body)
    |> return_validation_result(body)
  end

  # Private validation functions

  defp validate_required_fields(errors, body, :collections) do
    required_fields = [:amount, :currency, :externalId, :payer]
    validate_fields_present(body, required_fields, errors)
  end

  defp validate_required_fields(errors, body, :disbursements) do
    required_fields = [:amount, :currency, :externalId, :payee]
    validate_fields_present(body, required_fields, errors)
  end

  defp validate_fields_present(_body, [], errors), do: errors

  defp validate_fields_present(body, [field | rest], errors) do
    case Map.get(body, field) do
      nil ->
        error = %{field: field, message: "#{field} is required", value: nil}
        validate_fields_present(body, rest, [error | errors])

      value when value == "" ->
        error = %{field: field, message: "#{field} cannot be empty", value: value}
        validate_fields_present(body, rest, [error | errors])

      _value ->
        validate_fields_present(body, rest, errors)
    end
  end

  defp validate_amount(errors, body) do
    new_errors = case Map.get(body, :amount) do
      nil -> []
      "" -> []
      amount when is_binary(amount) ->
        case Float.parse(amount) do
          {float_value, ""} when float_value > 0 -> []
          {_float_value, ""} -> [%{field: :amount, message: "Amount must be positive", value: amount}]
          _ ->
            # Try integer parse as fallback
            case Integer.parse(amount) do
              {int_value, ""} when int_value > 0 -> []
              {_int_value, ""} -> [%{field: :amount, message: "Amount must be positive", value: amount}]
              _ -> [%{field: :amount, message: "Amount must be a valid number", value: amount}]
            end
        end
      amount ->
        [%{field: :amount, message: "Amount must be a string", value: amount}]
    end
    new_errors ++ errors
  end

  defp validate_currency(errors, body) do
    new_errors = case Map.get(body, :currency) do
      nil -> []
      "" -> []
      currency when is_binary(currency) ->
        if String.length(currency) == 3 and String.match?(currency, ~r/^[A-Z]{3}$/) do
          []
        else
          [%{field: :currency, message: "Currency must be a 3-letter ISO code (e.g., UGX, EUR)", value: currency}]
        end
      currency ->
        [%{field: :currency, message: "Currency must be a string", value: currency}]
    end
    new_errors ++ errors
  end

  defp validate_external_id(errors, body) do
    new_errors = case Map.get(body, :externalId) do
      nil -> []
      "" -> [%{field: :externalId, message: "External ID cannot be empty", value: ""}]
      external_id when is_binary(external_id) -> []
      external_id -> [%{field: :externalId, message: "External ID must be a string", value: external_id}]
    end
    new_errors ++ errors
  end

  defp validate_payer(errors, body) do
    new_errors = case Map.get(body, :payer) do
      nil -> []
      payer when is_map(payer) ->
        validate_party(payer, :payer)
      payer ->
        [%{field: :payer, message: "Payer must be a map", value: payer}]
    end
    new_errors ++ errors
  end

  defp validate_payee(errors, body) do
    new_errors = case Map.get(body, :payee) do
      nil -> []
      payee when is_map(payee) ->
        validate_party(payee, :payee)
      payee ->
        [%{field: :payee, message: "Payee must be a map", value: payee}]
    end
    new_errors ++ errors
  end

  defp validate_party(party, party_type) do
    errors = []

    errors = case Map.get(party, :partyIdType) do
      nil -> [%{field: :"#{party_type}.partyIdType", message: "Party ID type is required", value: nil} | errors]
      "" -> [%{field: :"#{party_type}.partyIdType", message: "Party ID type cannot be empty", value: ""} | errors]
      type when type in ["MSISDN", "EMAIL", "PARTY_CODE"] -> errors
      type -> [%{field: :"#{party_type}.partyIdType", message: "Party ID type must be one of: MSISDN, EMAIL, PARTY_CODE", value: type} | errors]
    end

    case Map.get(party, :partyId) do
      nil -> [%{field: :"#{party_type}.partyId", message: "Party ID is required", value: nil} | errors]
      "" -> [%{field: :"#{party_type}.partyId", message: "Party ID cannot be empty", value: ""} | errors]
      party_id when is_binary(party_id) -> validate_party_id_format(party_id, Map.get(party, :partyIdType), party_type, errors)
      party_id -> [%{field: :"#{party_type}.partyId", message: "Party ID must be a string", value: party_id} | errors]
    end
  end

  defp validate_party_id_format(party_id, "MSISDN", party_type, errors) do
    # Basic MSISDN validation - should be digits, optionally starting with +
    if String.match?(party_id, ~r/^\+?[0-9]{10,15}$/) do
      errors
    else
      [%{field: :"#{party_type}.partyId", message: "MSISDN must be 10-15 digits, optionally starting with +", value: party_id} | errors]
    end
  end

  defp validate_party_id_format(party_id, "EMAIL", party_type, errors) do
    # Basic email validation
    if String.match?(party_id, ~r/^[^\s]+@[^\s]+\.[^\s]+$/) do
      errors
    else
      [%{field: :"#{party_type}.partyId", message: "Invalid email format", value: party_id} | errors]
    end
  end

  defp validate_party_id_format(_party_id, _type, _party_type, errors) do
    # For PARTY_CODE or other types, we accept any non-empty string
    errors
  end

  defp validate_messages(errors, body) do
    new_errors = []

    new_errors = case Map.get(body, :payerMessage) do
      nil -> new_errors
      message when is_binary(message) and byte_size(message) <= 160 -> new_errors
      message when is_binary(message) -> [%{field: :payerMessage, message: "Payer message cannot exceed 160 characters", value: message} | new_errors]
      message -> [%{field: :payerMessage, message: "Payer message must be a string", value: message} | new_errors]
    end

    new_errors = case Map.get(body, :payeeNote) do
      nil -> new_errors
      note when is_binary(note) and byte_size(note) <= 160 -> new_errors
      note when is_binary(note) -> [%{field: :payeeNote, message: "Payee note cannot exceed 160 characters", value: note} | new_errors]
      note -> [%{field: :payeeNote, message: "Payee note must be a string", value: note} | new_errors]
    end

    new_errors ++ errors
  end

  defp return_validation_result([], body), do: {:ok, body}
  defp return_validation_result(errors, _body), do: {:error, Enum.reverse(errors)}
end