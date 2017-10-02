defmodule Ollo.TokenModule do
  @moduledoc """
  Behaviour-spec for user-defined token module

  Token struct is expected to have
    - id
    - value (string)
    - user_id (string or UUID or integer)
    - client_id (string or UUID or integer)
    - expires_at (datetime)
  """

  @doc """
  Creates a token
  Errors are not expected, so raise an error if creation fails

  Returns a Token struct, which the user defines
  """
  @callback create_token!(atom, Map.t) :: struct
end
