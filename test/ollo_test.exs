defmodule OlloTest do
  use ExUnit.Case
  doctest Ollo

  describe ".get_client/1" do
    setup do
      {:ok, %{client_id: client_id}} = Ollo.register_client(%{name: "External App 1"})
      [client_id: client_id]
    end

    test "gets a client", %{client_id: id} do
      client = Ollo.get_client(id)
      assert client.client_id == id
    end
  end

  describe ".register_client/2" do
    test "adds a new client and assigns it a client_id" do
      {:ok, %{client_id: client_id}} = Ollo.register_client(%{name: "External App 1"})
      assert client_id
    end
  end
end
