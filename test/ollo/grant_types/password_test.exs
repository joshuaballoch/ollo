defmodule Ollo.GrantTypes.PasswordTest do
  use ExUnit.Case
  doctest Ollo.GrantTypes.Password

  @valid_password "password"
  @valid_scopes ["read"]

  setup do
    email = "email#{:rand.uniform(10000)}@mail.com"
    {:ok, %{id: user_id}} = Ollo.InMemoryUserModule.insert_user(%{email: email, password: @valid_password})
    {:ok, %{client_id: client_id}} = Ollo.register_client(%{name: "Some APp"})
    Application.put_env(:ollo, :allowed_scopes, @valid_scopes)

    [ client_id: client_id, user_id: user_id, email: email ]
  end

  describe "get_token/1 with valid email, password, and client_id" do

    test "returns refresh and access tokens to the caller", %{client_id: client_id, email: email} do
      attrs = %{email: email, password: @valid_password, client_id: client_id, scopes: @valid_scopes}
      {:ok, %{tokens: tokens}} = Ollo.GrantTypes.Password.get_tokens(attrs)

      assert length(tokens) == 2

      assert tokens[:refresh].value
      assert tokens[:access].value
    end

    test "grants access to the client", %{user_id: user_id, client_id: client_id, email: email} do
      attrs = %{email: email, password: @valid_password, client_id: client_id, scopes: @valid_scopes}
      {:ok, %{tokens: tokens}} = Ollo.GrantTypes.Password.get_tokens(attrs)

      is_authorized = Ollo.authorized?(%{client_id: client_id, user_id: user_id, scope: "read"})
      assert is_authorized == true
    end
  end

  describe "get_token/1 with invalid email" do

    test "returns invalid_email_password_combo error", %{client_id: client_id} do
      attrs = %{email: "some@unknown.com", password: @valid_password, client_id: client_id, scopes: @valid_scopes}
      {:error, %{error: error}} = Ollo.GrantTypes.Password.get_tokens(attrs)
      assert error == :invalid_email_password_combo
    end
  end

  describe "get_token/1 with an invalid password" do

    test "returns invalid_email_password_combo error", %{client_id: client_id, email: email} do
      attrs = %{email: email, password: "invalidpw", client_id: client_id, scopes: @valid_scopes}
      {:error, %{error: error}} = Ollo.GrantTypes.Password.get_tokens(attrs)
      assert error == :invalid_email_password_combo
    end
  end

  describe "get_token/1 with an invalid scope" do

    test "returns invalid scope error", %{client_id: client_id, email: email} do
      attrs = %{email: email, password: @valid_password, client_id: client_id, scopes: ["admin"]}
      {:error, %{error: error}} = Ollo.GrantTypes.Password.get_tokens(attrs)
      assert error == :invalid_scope
    end
  end

  describe "get_token/1 with an invalid client id" do

    test "returns invalid client id error", %{email: email} do
      attrs = %{email: email, password: @valid_password, client_id: "someid", scopes: @valid_scopes}
      {:error, %{error: error}} = Ollo.GrantTypes.Password.get_tokens(attrs)
      assert error == :invalid_client_id
    end
  end
end
