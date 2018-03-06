defmodule Ollo.GrantTypes.DeviceFlowTest do
  use ExUnit.Case
  doctest Ollo.GrantTypes.DeviceFlow

  setup do
    Application.put_env(:ollo, :allowed_scopes, ["read", "write"])
  end

  describe ".get_temp_code/1 with a valid client_id" do
    setup do
      {:ok, client} = Ollo.register_client(%{name: "Some app"})
      [client_id: client.client_id]
    end

    test "returns device and user codes plus their time until expiry", %{client_id: client_id} do
      {:ok, %{
        device_code: device_code,
        user_code: user_code,
        expires_in: expires_in
      }} = Ollo.GrantTypes.DeviceFlow.get_temp_code(%{client_id: client_id, scopes: ["read"]})
      assert device_code
      assert user_code
      assert expires_in === 600
    end

    test "sets an initial status on the device token", %{client_id: client_id} do
      {:ok, %{device_code: device_code}} = Ollo.GrantTypes.DeviceFlow.get_temp_code(%{client_id: client_id, scopes: ["read"]})
      assert Ollo.Config.persistence_module.get_token(:device_code, device_code).status == "pending"
    end

    test "sets a requested scope on the device token", %{client_id: client_id} do
      {:ok, %{device_code: device_code}} = Ollo.GrantTypes.DeviceFlow.get_temp_code(%{client_id: client_id, scopes: ["read"]})
      assert Ollo.Config.persistence_module.get_token(:device_code, device_code).requested_scopes == ["read"]
    end

    test "relates the user token to its parent device token", %{client_id: client_id} do
      {:ok, %{
        device_code: device_code,
        user_code: user_code
      }} = Ollo.GrantTypes.DeviceFlow.get_temp_code(%{client_id: client_id, scopes: ["read"]})

      assert Ollo.Config.persistence_module.get_token(:user_code, user_code).parent_token_value == device_code
    end
  end

  describe ".get_temp_code/1 with an invalid scope" do
    setup do
      {:ok, %{client_id: client_id}} = Ollo.register_client(%{name: "bob"})
      [client_id: client_id]
    end

    test "returns invalid_scope error", %{client_id: client_id} do
      {:error, %{error: error}} = Ollo.GrantTypes.DeviceFlow.get_temp_code(%{
        client_id: client_id,
        scopes: ["some-invalid-scope"]
      })

      assert error == :invalid_scope
    end
  end

  describe ".get_temp_code/1 with an invalid client_id" do

    test "returns device and user codes plus their time until expiry" do
      {:error, %{
        error: error
      }} = Ollo.GrantTypes.DeviceFlow.get_temp_code(%{client_id: "something", scopes: ["read"]})
      assert error == :invalid_client_id
    end
  end

  describe ".get_temp_code_info/1 with a valid user_code" do
    setup do
      {:ok, %{client_id: client_id} = client} = Ollo.register_client(%{name: "Some App"})
      Application.put_env(:ollo, :allowed_scopes, ["read", "write"])
      {:ok, %{
        user_code: user_code
      }} = Ollo.GrantTypes.DeviceFlow.get_temp_code(%{client_id: client_id, scopes: ["read"]})
      [client: client, user_code: user_code]
    end

    test "returns info about the client and requested scopes", %{user_code: user_code, client: client} do
      info = Ollo.GrantTypes.DeviceFlow.get_temp_code_info(user_code)

      assert info == %{
        client: client,
        requested_scopes: ["read"],
        status: "pending"
      }
    end
  end

  describe ".get_temp_code_info/1 with a invalid user_code" do

    test "returns nil" do
      refute Ollo.GrantTypes.DeviceFlow.get_temp_code_info("asdf")
    end
  end

  describe ".grant_authorization/1 with valid user_code and user_id" do
    setup do
      {:ok, %{client_id: client_id}} = Ollo.register_client(%{name: "asdf"})
      {:ok, %{id: user_id}} = Ollo.InMemoryUserModule.insert_user(%{email: "any@com", password: "asdfasdf"})
      {:ok, %{
        device_code: device_code,
        user_code: user_code
      }} = Ollo.GrantTypes.DeviceFlow.get_temp_code(%{client_id: client_id, scopes: ["read"]})
      [
        user_code: user_code,
        device_code: device_code,
        user_id: user_id,
        client_id: client_id
      ]
    end

    test "grants the client authorization to access the user's account", params do
      {:ok, _} = Ollo.GrantTypes.DeviceFlow.grant_authorization(%{
        user_id: params[:user_id],
        code: params[:user_code]
      })
      is_authorized = Ollo.authorized?(%{
        client_id: params[:client_id],
        user_id: params[:user_id],
        scope: "read"
      })
      assert is_authorized == true
    end

    test "updates the device_token status to granted", params do
      {:ok, _} = Ollo.GrantTypes.DeviceFlow.grant_authorization(%{
        user_id: params[:user_id],
        code: params[:user_code]
      })
      device_token = Ollo.Config.persistence_module.get_token(:device_code, params[:device_code])
      assert device_token.status == "granted"
    end

    test "updates the device_token user_id to the user", params do
      {:ok, _} = Ollo.GrantTypes.DeviceFlow.grant_authorization(%{
        user_id: params[:user_id],
        code: params[:user_code]
      })
      device_token = Ollo.Config.persistence_module.get_token(:device_code, params[:device_code])
      assert device_token.user_id == params[:user_id]
    end
  end

  describe ".grant_authorization/1 with invalid user_code" do
    setup do
      {:ok, %{id: user_id}} = Ollo.InMemoryUserModule.insert_user(%{email: "any@com", password: "asdfasdf"})
      [user_id: user_id]
    end

    test "returns invalid_user_code error", params do
      {:error, %{error: error}} = Ollo.GrantTypes.DeviceFlow.grant_authorization(%{
        user_id: params[:user_id],
        code: "fake-code"
      })
      assert error == :invalid_user_code
    end
  end

  describe ".reject_temp_code/1 with valid user code" do
    setup do
      {:ok, %{client_id: client_id}} = Ollo.register_client(%{name: "Some app"})
      {:ok, %{
        device_code: device_code,
        user_code: user_code
      }} = Ollo.GrantTypes.DeviceFlow.get_temp_code(%{client_id: client_id, scopes: ["read"]})
      [user_code: user_code, device_code: device_code]
    end

    test "updates the device code status to rejected", params do
      {:ok, %{}} = Ollo.GrantTypes.DeviceFlow.reject_temp_code(params[:user_code])
      assert Ollo.Config.persistence_module.get_token(:device_code, params[:device_code]).status == "rejected"
    end
  end

  describe ".reject_temp_code/1 with invalid user code" do

    test "returns invalid_user_code error" do
      {:error, %{error: error}} = Ollo.GrantTypes.DeviceFlow.reject_temp_code("invalid-user-code")
      assert error == :invalid_user_code
    end
  end

  describe ".get_tokens/1 with granted device_code" do
    setup do
      {:ok, client} = Ollo.register_client(%{name: "adsf"})
      {:ok, %{
        device_code: device_code,
        user_code: user_code
      }} = Ollo.GrantTypes.DeviceFlow.get_temp_code(%{client_id: client.client_id, scopes: ["read"]})
      {:ok, %{id: user_id}} = Ollo.InMemoryUserModule.insert_user(%{email: @valid_email, password: @valid_password})
      {:ok, _} = Ollo.GrantTypes.DeviceFlow.grant_authorization(%{code: user_code, user_id: user_id})
      [
        client_id: client.client_id,
        user_id: user_id,
        code: device_code,
        user_code: user_code
      ]
    end

    test "returns access and refresh tokens", %{client_id: client_id, code: code} do
      {:ok, %{tokens: tokens}} = Ollo.GrantTypes.DeviceFlow.get_tokens(%{code: code, client_id: client_id})
      assert length(tokens) == 2
      assert tokens[:refresh].value
      assert tokens[:access].value
    end

    test "only grants access tokens once", %{client_id: client_id, code: code, user_code: user_code} do
      {:ok, %{tokens: tokens}} = Ollo.GrantTypes.DeviceFlow.get_tokens(%{code: code, client_id: client_id})

      {:error, %{error: error}} = Ollo.GrantTypes.DeviceFlow.get_tokens(%{code: code, client_id: client_id})
      assert error == :invalid_device_code
      refute Ollo.Config.persistence_module.get_token(:user_code, user_code)
    end
  end

  describe ".get_tokens/1 with pending device_code" do
    setup do
      {:ok, client} = Ollo.register_client(%{name: "adsf"})
      {:ok, %{device_code: device_code}} = Ollo.GrantTypes.DeviceFlow.get_temp_code(%{client_id: client.client_id, scopes: ["read"]})
      [client_id: client.client_id, code: device_code]
    end

    test "returns pending error", %{client_id: client_id, code: code} do
      {:error, %{error: error}} = Ollo.GrantTypes.DeviceFlow.get_tokens(%{code: code, client_id: client_id})
      assert error == :pending
    end
  end

  describe ".get_tokens/1 with rejected device_code" do
    setup do
      {:ok, client} = Ollo.register_client(%{name: "adsf"})
      {:ok,
        %{device_code: device_code,
          user_code: user_code}} = Ollo.GrantTypes.DeviceFlow.get_temp_code(%{client_id: client.client_id, scopes: ["read"]})
      {:ok, _} = Ollo.GrantTypes.DeviceFlow.reject_temp_code(user_code)
      [client_id: client.client_id, code: device_code]
    end

    test "returns a rejected error", %{client_id: client_id, code: code} do
      {:error, %{error: error}} = Ollo.GrantTypes.DeviceFlow.get_tokens(%{code: code, client_id: client_id})
      assert error == :rejected
    end
  end

  describe ".get_tokens/1 with an expired device_code" do
    setup do
      {:ok, client} = Ollo.register_client(%{name: "adsf"})
      {:ok, %{
        device_code: device_code,
        user_code: user_code
      }} = Ollo.GrantTypes.DeviceFlow.get_temp_code(%{client_id: client.client_id, scopes: ["read"]})

      token = Ollo.Config.persistence_module.get_token(:device_code, device_code)
      Ollo.InMemoryTokenModule.update_token(token, %{expires_at: DateTime.from_unix!(1)})
      [client_id: client.client_id, code: device_code]
    end

    test "returns expired grant error", %{client_id: client_id, code: code} do
      {:error, %{error: error}} = Ollo.GrantTypes.DeviceFlow.get_tokens(%{code: code, client_id: client_id})
      assert error == :expired_grant
    end
  end

  describe ".get_tokens/1 with invalid device_code" do
    setup do
      {:ok, client} = Ollo.register_client(%{name: "adsf"})
      [client_id: client.client_id]
    end

    test "returns invalid code error", %{client_id: client_id} do
      {:error, %{error: error}} = Ollo.GrantTypes.DeviceFlow.get_tokens(%{code: "some-code", client_id: client_id})
      assert error == :invalid_device_code
    end
  end

  describe ".get_tokens/1 with valid device_code but non-corresponding client_id" do
    setup do
      {:ok, client} = Ollo.register_client(%{name: "adsf"})
      {:ok, %{device_code: device_code}} = Ollo.GrantTypes.DeviceFlow.get_temp_code(%{client_id: client.client_id, scopes: ["read"]})
      {:ok, other_client} = Ollo.register_client(%{name: "other-adsf"})
      [code: device_code, other_client: other_client.client_id]
    end

    test "returns invalid device code error", %{code: code, other_client: other_client} do
      {:error, %{error: error}} = Ollo.GrantTypes.DeviceFlow.get_tokens(%{code: code, client_id: other_client})
      assert error == :invalid_device_code
    end
  end

  describe ".get_tokens/1 with non-device_code token" do
    setup do
      {:ok, %{client_id: client_id}} = Ollo.register_client(%{name: "adsf"})
      [client_id: client_id]
    end

    test "returns invalid device code error", %{client_id: client_id} do
      token = Ollo.Helpers.create_token!(:user_code, %{client_id: client_id})
      {:error, %{error: error}} = Ollo.GrantTypes.DeviceFlow.get_tokens(%{code: token.value, client_id: client_id})
      assert error == :invalid_device_code
    end
  end

  describe ".get_tokens/1 with invalid client_id" do

    test "returns invalid code error" do
      {:error, %{error: error}} = Ollo.GrantTypes.DeviceFlow.get_tokens(%{code: "some-code", client_id: "asdfasdf"})
      assert error == :invalid_client_id
    end
  end
end
