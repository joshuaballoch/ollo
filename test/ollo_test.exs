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

  describe ".get_temp_code/2 for user_flow, with valid client_id and scope" do
    setup do
      {:ok, %{client_id: client_id}} = Ollo.register_client(%{name: "Some App"})
      Application.put_env(:ollo, :allowed_scopes, ["read", "write"])
      [client_id: client_id]
    end

    test "returns user and device codes", %{client_id: client_id} do
      {:ok, %{
        device_code: device_code,
        user_code: user_code,
        expires_in: expires_in
      }} = Ollo.get_temp_code(:device_flow, %{client_id: client_id, scopes: ["read"]})

      assert device_code
      assert user_code
      assert expires_in
    end
  end

  describe ".get_temp_code_info/2 on device_flow with a valid user_code" do
    setup do
      {:ok, %{client_id: client_id} = client} = Ollo.register_client(%{name: "Some App"})
      Application.put_env(:ollo, :allowed_scopes, ["read", "write"])
      {:ok, %{
        user_code: user_code
      }} = Ollo.get_temp_code(:device_flow, %{client_id: client_id, scopes: ["read"]})
      [client: client, user_code: user_code]
    end

    test "returns info about the client and requested scopes", %{user_code: user_code, client: client} do
      info = Ollo.get_temp_code_info(:device_flow, user_code)

      assert info == %{
        client: client,
        requested_scopes: ["read"],
        status: "pending"
      }
    end
  end

  describe ".grant_client_authorization/1 with valid client_id, user, and scope" do
    setup do
      {:ok, %{client_id: client_id}} = Ollo.register_client(%{name: "External App 1"})
      {:ok, %{id: user_id}} = Ollo.InMemoryUserModule.insert_user(%{email: "asdf@oih#{:rand.uniform(10000)}.com", password: "password123"})
      Application.put_env(:ollo, :allowed_scopes, ["read", "write"])

      [
        client_id: client_id,
        user_id: user_id
      ]
    end

    test "returns :ok and the client_auth struct", %{client_id: client_id, user_id: user_id} do
      {:ok, client_auth} = Ollo.grant_client_authorization(%{client_id: client_id, user_id: user_id, scopes: ["read"]})
      assert client_auth
    end
  end

  describe ".grant_client_authorization/1 with invalid client_id" do
    setup do
      {:ok, %{id: user_id}} = Ollo.InMemoryUserModule.insert_user(%{email: "asdf@oih#{:rand.uniform(10000)}.com", password: "password123"})
      Application.put_env(:ollo, :allowed_scopes, ["read", "write"])

      [ user_id: user_id ]
    end

    test "returns an error :invalid_client_id", %{user_id: user_id} do
      {:error, %{error: error_code}} = Ollo.grant_client_authorization(%{client_id: "client-id-whatever", user_id: user_id, scopes: ["read"]})
      assert error_code == :invalid_client_id
    end
  end

  describe ".grant_client_authorization/1 with scope not in allowed_scopes" do
    setup do
      {:ok, %{client_id: client_id}} = Ollo.register_client(%{name: "External App 1"})
      {:ok, %{id: user_id}} = Ollo.InMemoryUserModule.insert_user(%{email: "asdf@oih#{:rand.uniform(10000)}.com", password: "password123"})
      Application.put_env(:ollo, :allowed_scopes, ["read", "write"])

      [
        client_id: client_id,
        user_id: user_id
      ]
    end

    test "returns an error :invalid_scope", %{client_id: client_id, user_id: user_id} do
      {:error, %{error: error_code}} = Ollo.grant_client_authorization(%{client_id: client_id, user_id: user_id, scopes: ["admin"]})
      assert error_code == :invalid_scope
    end
  end

  describe ".grant_client_authorization/2 with valid user_id and user_code" do
    setup do
      Application.put_env(:ollo, :allowed_scopes, ["read", "write"])
      {:ok, %{client_id: client_id}} = Ollo.register_client(%{name: "Some app"})
      {:ok, %{id: user_id}} = Ollo.InMemoryUserModule.insert_user(%{email: "asdf@adsf", password: "asdfasdf"})
      {:ok, %{user_code: user_code}} = Ollo.get_temp_code(:device_flow, %{client_id: client_id, scopes: ["read"]})
      [client_id: client_id, user_id: user_id, user_code: user_code]
    end

    test "returns ok with client authorization", %{user_code: user_code, user_id: user_id, client_id: client_id} do
      {:ok, client_auth} = Ollo.grant_client_authorization(:device_flow, %{user_code: user_code, user_id: user_id})
      assert client_auth.client_id == client_id
    end
  end

  describe ".authorized?/1" do
    setup do
      {:ok, %{client_id: client_id}} = Ollo.register_client(%{name: "Some App"})
      {:ok, %{id: user_id}} = Ollo.InMemoryUserModule.insert_user(%{email: "anything", password: "asdf"})
      [client_id: client_id, user_id: user_id]
    end

    test "returns true when the client is authorized for specific user and scope", params do
      {:ok, _} = Ollo.Config.persistence_module.grant_authorization(%{
        user_id: params[:user_id],
        client_id: params[:client_id],
        scopes: ["read"]
      })
      is_authorized = Ollo.authorized?(%{
        user_id: params[:user_id],
        client_id: params[:client_id],
        scope: "read"
      })
      assert is_authorized == true
    end

    test "returns false when the client is not authorized for the specific scope", params do
      {:ok, _} = Ollo.Config.persistence_module.grant_authorization(%{
        user_id: params[:user_id],
        client_id: params[:client_id],
        scopes: ["write"]
      })
      is_authorized = Ollo.authorized?(%{
        user_id: params[:user_id],
        client_id: params[:client_id],
        scope: "read"
      })
      assert is_authorized == false
    end

    test "returns false when the client is not authorized for the specific user", params do
      {:ok, _} = Ollo.Config.persistence_module.grant_authorization(%{
        user_id: "other-user-id",
        client_id: params[:client_id],
        scopes: ["read"]
      })
      is_authorized = Ollo.authorized?(%{
        user_id: params[:user_id],
        client_id: params[:client_id],
        scope: "read"
      })
      assert is_authorized == false
    end

    test "returns false when the client is not a valid client_id", params do
      {:ok, _} = Ollo.Config.persistence_module.grant_authorization(%{
        user_id: params[:user_id],
        client_id: params[:client_id],
        scopes: ["read"]
      })
      is_authorized = Ollo.authorized?(%{
        user_id: params[:user_id],
        client_id: "other-client-id",
        scope: "read"
      })
      assert is_authorized == false
    end
  end

  describe ".reject_temp_code/2 in device_flow with valid user_code" do
    setup do
      Application.put_env(:ollo, :allowed_scopes, ["read", "write"])
      {:ok, %{client_id: client_id}} = Ollo.register_client(%{name: "Some app"})
      {:ok, %{user_code: user_code}} = Ollo.GrantTypes.DeviceFlow.get_temp_code(%{client_id: client_id, scopes: ["read"]})
      [user_code: user_code]
    end

    test "returns ok", %{user_code: user_code} do
      res = Ollo.reject_temp_code(:device_flow, user_code)
      assert res == {:ok, %{}}
    end
  end

  describe ".reject_temp_code/2 in device_flow with invalid user_code" do
    test "returns an invalid_user_code error" do
      res = Ollo.reject_temp_code(:device_flow, "fake-user-code")
      assert res == {:error, %{error: :invalid_user_code}}
    end
  end

  describe ".get_tokens/2 for a given grant" do
    @valid_email "email#{:rand.uniform(10000)}@mail.com"
    @valid_password "password"
    @valid_scopes ["read"]

    setup do
      {:ok, _} = Ollo.InMemoryUserModule.insert_user(%{email: @valid_email, password: @valid_password})
      {:ok, %{client_id: client_id}} = Ollo.register_client(%{name: "Some APp"})
      Application.put_env(:ollo, :allowed_scopes, @valid_scopes)

      [ client_id: client_id ]
    end

    test "works when grant is enabled", %{client_id: client_id} do
      Application.put_env(:ollow, :enabled_grants, %{password: Ollo.GrantTypes.Password})
      attrs = %{email: @valid_email, password: @valid_password, client_id: client_id, scopes: @valid_scopes}
      {:ok, %{tokens: _}} = Ollo.get_tokens(:password, attrs)
    end

    test "raises an error when grant is disabled" do
      Application.put_env(:ollow, :enabled_grants, %{})
      assert_raise FunctionClauseError, fn ->
        Ollo.get_tokens(:password, %{})
      end
    end
  end
end
