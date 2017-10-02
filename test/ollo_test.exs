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

  describe "create_client_authorization/3 with valid client_id, user, and scope" do
    setup do
      {:ok, %{client_id: client_id}} = Ollo.register_client(%{name: "External App 1"})
      {:ok, %{id: user_id}} = Ollo.Config.user_module.insert_user(%{email: "asdf@oih#{:rand.uniform(10000)}.com", password: "password123"})
      Application.put_env(:ollo, :allowed_scopes, ["read", "write"])

      [
        client_id: client_id,
        user_id: user_id
      ]
    end

    test "returns :ok and the client_auth struct", %{client_id: client_id, user_id: user_id} do
      {:ok, client_auth} = Ollo.grant_client_authorization(%{client_id: client_id, user_id: user_id, scope: ["read"]})
      assert client_auth
    end
  end

  describe "create_client_authorization/3 with invalid client_id" do
    setup do
      {:ok, %{id: user_id}} = Ollo.Config.user_module.insert_user(%{email: "asdf@oih#{:rand.uniform(10000)}.com", password: "password123"})
      Application.put_env(:ollo, :allowed_scopes, ["read", "write"])

      [ user_id: user_id ]
    end

    test "returns an error :invalid_client_id", %{user_id: user_id} do
      {:error, %{error: error_code}} = Ollo.grant_client_authorization(%{client_id: "client-id-whatever", user_id: user_id, scope: ["read"]})
      assert error_code == :invalid_client_id
    end
  end

  describe "create_client_authorization/3 with scope not in allowed_scopes" do
    setup do
      {:ok, %{client_id: client_id}} = Ollo.register_client(%{name: "External App 1"})
      {:ok, %{id: user_id}} = Ollo.Config.user_module.insert_user(%{email: "asdf@oih#{:rand.uniform(10000)}.com", password: "password123"})
      Application.put_env(:ollo, :allowed_scopes, ["read", "write"])

      [
        client_id: client_id,
        user_id: user_id
      ]
    end

    test "returns an error :invalid_scope", %{client_id: client_id, user_id: user_id} do
      {:error, %{error: error_code}} = Ollo.grant_client_authorization(%{client_id: client_id, user_id: user_id, scope: ["admin"]})
      assert error_code == :invalid_scope
    end
  end

  describe "get_tokens/2 for a given grant" do
    @valid_email "email#{:rand.uniform(10000)}@mail.com"
    @valid_password "password"
    @valid_scopes ["read"]

    setup do
      {:ok, _} = Ollo.Config.user_module.insert_user(%{email: @valid_email, password: @valid_password})
      {:ok, %{client_id: client_id}} = Ollo.register_client(%{name: "Some APp"})
      Application.put_env(:ollo, :allowed_scopes, @valid_scopes)

      [ client_id: client_id ]
    end

    test "works when grant is enabled", %{client_id: client_id} do
      Application.put_env(:ollow, :enabled_grants, %{password: Ollo.GrantTypes.Password})
      attrs = %{email: @valid_email, password: @valid_password, client_id: client_id, scope: @valid_scopes}
      {:ok, tokens: _} = Ollo.get_tokens(:password, attrs)
    end

    test "raises an error when grant is disabled" do
      Application.put_env(:ollow, :enabled_grants, %{})
      assert_raise FunctionClauseError, fn ->
        Ollo.get_tokens(:password, %{})
      end
    end
  end
end
