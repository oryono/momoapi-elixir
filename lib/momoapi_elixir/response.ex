defmodule MomoapiElixir.Response do
  def handle_response(body) do
    IO.inspect body
    case body do
      {:ok, %HTTPoison.Response{status_code: 404, body: body}} -> {:error, body }
      {:ok, %HTTPoison.Response{status_code: 202, body: ""}} -> ""
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} -> body
      {:error, %HTTPoison.Error{id: _, reason: reason} = error} -> {:error, reason}
    end
  end

  def handle_error(error) do
    {:error, "An error occurred"}
  end
end