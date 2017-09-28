defmodule OlloTest do
  use ExUnit.Case
  doctest Ollo

  test "greets the world" do
    assert Ollo.hello() == :world
  end
end
