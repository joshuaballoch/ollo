defmodule Ollo.GrantTypes.PasswordTest do
  use ExUnit.Case

  @valid_email "email#{:rand.uniform(10000)}@mail.com"
  @valid_password "password"
  @valid_scopes ["read"]

  setup do
    {:ok, _} = Ollo.Config.user_module.insert_user(%{email: @valid_email, password: @valid_password})
    {:ok, %{client_id: client_id}} = Ollo.register_client(%{name: "Some APp"})
    Application.put_env(:ollo, :allowed_scopes, @valid_scopes)

    [ client_id: client_id ]
  end

  describe "get_token/1 with valid email, password, and client_id" do

    test "returns refresh and access tokens to the caller", %{client_id: client_id} do
      attrs = %{email: @valid_email, password: @valid_password, client_id: client_id, scope: @valid_scopes}
      {:ok, tokens: tokens} = Ollo.GrantTypes.Password.get_tokens(attrs)

      assert length(tokens) == 2

      assert tokens[:refresh].value
      assert tokens[:access].value
    end
  end

  describe "get_token/1 with invalid email" do

    test "returns invalid_email_password_combo error", %{client_id: client_id} do
      attrs = %{email: "some@unknown.com", password: @valid_password, client_id: client_id, scope: @valid_scopes}
      {:error, %{error: error}} = Ollo.GrantTypes.Password.get_tokens(attrs)
      assert error == :invalid_email_password_combo
    end
  end

  describe "get_token/1 with an invalid password" do

    test "returns invalid_email_password_combo error", %{client_id: client_id} do
      attrs = %{email: @valid_email, password: "invalidpw", client_id: client_id, scope: @valid_scopes}
      {:error, %{error: error}} = Ollo.GrantTypes.Password.get_tokens(attrs)
      assert error == :invalid_email_password_combo
    end
  end

  describe "get_token/1 with an invalid scope" do

    test "returns invalid scope error", %{client_id: client_id} do
      attrs = %{email: @valid_email, password: @valid_password, client_id: client_id, scope: ["admin"]}
      {:error, %{error: error}} = Ollo.GrantTypes.Password.get_tokens(attrs)
      assert error == :invalid_scope
    end
  end

  describe "get_token/1 with an invalid client id" do

    test "returns invalid client id error" do
      attrs = %{email: @valid_email, password: @valid_password, client_id: "someid", scope: @valid_scopes}
      {:error, %{error: error}} = Ollo.GrantTypes.Password.get_tokens(attrs)
      assert error == :invalid_client_id
    end
  end
end
