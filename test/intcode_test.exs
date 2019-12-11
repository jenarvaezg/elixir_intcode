defmodule IntcodeTest do
  use ExUnit.Case
  doctest Intcode

  test "greets the world" do
    assert Intcode.hello() == :world
  end
end
