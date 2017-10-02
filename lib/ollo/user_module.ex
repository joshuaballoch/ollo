defmodule Ollo.UserModule do
  @moduledoc """
  Behaviour-spec for user-defined user module

  User struct is expected to have id, email, and password attributes
  """

  @callback get_user_by_email(String.t) :: struct # or nil
  @callback match_pw(struct, String.t) :: boolean
end
