# Test User Module behaviours
defmodule Ollo.UserModuleTest do
  use ExUnit.Case

  describe "get_user_by_email/1" do
    setup do
      email = "test@email.com"
      {:ok, _} = Ollo.Config.user_module.insert_user(%{email: email, password: "asdfasdf"})
      [email: email]
    end

    test "returns nil for no match" do
      refute Ollo.Config.user_module.get_user_by_email("asdf@oiasdf.com")
    end

    test "returns user struct for match", %{email: email} do
      user = Ollo.Config.user_module.get_user_by_email(email)
      assert user.email == email
    end
  end

  describe "match_pw/2" do
    setup do
      {:ok, user} = Ollo.Config.user_module.insert_user(%{email: "test@oihasdf.com", password: "real_password"})
      [user: user]
    end

    test "returns true for matching password", %{user: user} do
      assert Ollo.Config.user_module.match_pw(user, "real_password") == true
    end

    test "returns false for wrong password", %{user: user} do
      assert Ollo.Config.user_module.match_pw(user, "asdfasdf") == false
    end
  end
end
