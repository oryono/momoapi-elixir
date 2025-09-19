defmodule MomoapiElixir.ClientBehaviour do
  @callback post(String.t(), map(), [{String.t(), String.t()}]) :: {:ok, map()} | {:error, term()}
  @callback get(String.t(), [{String.t(), String.t()}]) :: {:ok, map()} | {:error, term()}
end