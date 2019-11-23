defmodule MomoapiElixirTest do
  use ExUnit.Case
  doctest MomoapiElixir

  test "greets the world" do
    assert MomoapiElixir.hello() == :world
  end
end
