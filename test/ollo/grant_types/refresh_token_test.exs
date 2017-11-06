defmodule Ollo.GrantTypes.RefreshTokenTest do
  use ExUnit.Case
  doctest Ollo.GrantTypes.RefreshToken
  import Ollo.Helpers

  setup do
    {:ok, %{client_id: client_id}} = Ollo.register_client(%{name: "Some APp"})

    [client_id: client_id]
  end

  describe "get_token/1 with valid refresh token" do
    setup %{client_id: client_id} do
      refresh_token = create_token!(:refresh, %{client_id: client_id, user_id: 123})

      [refresh_token: refresh_token]
    end

    test "returns refresh and access tokens to the caller", %{client_id: client_id, refresh_token: refresh_token} do
      attrs = %{code: refresh_token.value, client_id: client_id}
      {:ok, %{tokens: tokens}} = Ollo.GrantTypes.RefreshToken.get_tokens(attrs)

      assert length(tokens) == 2

      assert tokens[:refresh].value
      assert tokens[:access].value
    end

    test "associates new tokens to past user and client", %{client_id: client_id, refresh_token: refresh_token} do
      attrs = %{code: refresh_token.value, client_id: client_id}
      {:ok, %{tokens: tokens}} = Ollo.GrantTypes.RefreshToken.get_tokens(attrs)

      assert Enum.all?(tokens, fn { type, token } -> token.user_id == refresh_token.user_id end)
      assert Enum.all?(tokens, fn { type, token } -> token.client_id == client_id end)
    end

    test "only works once for a refresh token", %{client_id: client_id, refresh_token: refresh_token} do
      attrs = %{code: refresh_token.value, client_id: client_id}
      {:ok, %{tokens: tokens}} = Ollo.GrantTypes.RefreshToken.get_tokens(attrs)
      {:error, %{error: error}} = Ollo.GrantTypes.RefreshToken.get_tokens(attrs)
      assert error == :invalid_token
    end
  end

  describe "get_token/1 with an expired refresh token" do
    setup %{client_id: client_id} do
      before_now = DateTime.utc_now |> DateTime.to_unix |> - 1000 |> DateTime.from_unix!

      refresh_token = create_token!(:refresh, %{client_id: client_id, user_id: 123})
                      |> Ollo.Config.persistence_module.update_token(%{expires_at: before_now})

      [refresh_token: refresh_token]
    end

    test "returns expired refresh token error", %{client_id: client_id, refresh_token: refresh_token} do
      attrs = %{client_id: client_id, code: refresh_token.value}
      {:error, %{error: error}} = Ollo.GrantTypes.RefreshToken.get_tokens(attrs)
      assert error == :expired_token
    end
  end

  describe "get_token/1 with an invalid refresh token" do

    test "returns invalid refresh token error", %{client_id: client_id} do
      attrs = %{client_id: client_id, code: "not-real-value"}
      {:error, %{error: error}} = Ollo.GrantTypes.RefreshToken.get_tokens(attrs)
      assert error == :invalid_token
    end
  end

  describe "get_token/1 with a different client's refresh token" do
    setup %{client_id: client_id} do
      refresh_token = create_token!(:refresh, %{client_id: "1234", user_id: 123})

      [refresh_token: refresh_token, client_id: client_id]
    end

    test "returns invalid refresh token error", %{client_id: client_id, refresh_token: refresh_token} do
      attrs = %{client_id: client_id, code: refresh_token.value}
      {:error, %{error: error}} = Ollo.GrantTypes.RefreshToken.get_tokens(attrs)
      assert error == :invalid_token
    end
  end

  describe "get_token/1 with an invalid client id" do
    setup %{client_id: client_id} do
      refresh_token = create_token!(:refresh, %{client_id: client_id, user_id: 123})

      [refresh_token: refresh_token]
    end

    test "returns invalid client id error", %{refresh_token: refresh_token} do
      attrs = %{client_id: "someid", code: refresh_token.value}
      {:error, %{error: error}} = Ollo.GrantTypes.RefreshToken.get_tokens(attrs)
      assert error == :invalid_client_id
    end
  end
end
