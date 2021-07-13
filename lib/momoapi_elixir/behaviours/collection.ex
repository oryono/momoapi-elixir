defmodule MomoapiElixir.Behaviours.Collection do
  @callback post(any, any, any) :: any
  @callback post(any, any) :: any
  @callback get(String.t(), any) :: any
end