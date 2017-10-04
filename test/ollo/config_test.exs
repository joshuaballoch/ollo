defmodule Ollo.ConfigTest do
  use ExUnit.Case
  doctest Ollo.Config

  test "options can be configured" do
    Application.put_env(:ollo, :persistence_module, :something)
    assert Ollo.Config.persistence_module == :something
  end
end
