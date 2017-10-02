defmodule Ollo.ConfigTest do
  use ExUnit.Case
  doctest Ollo.Config

  test "options can be configured" do
    Application.put_env(:ollo, :client_module, :something)
    assert Ollo.Config.client_module == :something
  end
end
