defmodule Ollo.HelpersTest do
  use ExUnit.Case
  import Ollo.Helpers

  describe "create_token/2 for a refresh token" do

    test "creates a token between the client and the user" do
      token = create_token!(:refresh, client_id: "12", user_id: "11")
      assert token.client_id == "12"
      assert token.user_id == "11"
      assert token.token_type == "refresh"
      assert token.value
    end

    test "sets the token expiry according to the config" do
      token = create_token!(:refresh, client_id: "12", user_id: "11")
      expected_expiry = DateTime.from_unix!((DateTime.utc_now |> DateTime.to_unix) + 24 * 7 * 3600)
      assert token.expires_at == expected_expiry
    end
  end

  describe "create_token/2 for an access token" do

    test "creates a token between the client and the user" do
      token = create_token!(:access, client_id: "12", user_id: "11")
      assert token.client_id == "12"
      assert token.user_id == "11"
      assert token.token_type == "access"
      assert token.value
    end

    test "sets the token expiry according to the config" do
      token = create_token!(:access, client_id: "12", user_id: "11")
      expected_expiry = DateTime.from_unix!((DateTime.utc_now |> DateTime.to_unix) + 24 * 3600)
      assert token.expires_at == expected_expiry
    end

    test "creates token that can be looked up after" do
      token = create_token!(:access, client_id: "12", user_id: "11")
      assert Ollo.Config.persistence_module.get_token(:access, token.value)
    end
  end
end
