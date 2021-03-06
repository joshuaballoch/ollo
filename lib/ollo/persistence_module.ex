defmodule Ollo.Persistence do
  @moduledoc """
  Behaviour spec for user to define integration of Ollo with their Persistence layer

  Users are free to use whatever they choose to store Clients, ClientAuthorizations, Tokens, and Users

  The behaviours below must be defined, and user's must implement structs
  with attributes consistent with what Ollo expects for Clients, ClientAuthorizations
  and Users.
  """

  ## START Client Behaviours

  @doc """
  Gets a client by their client_id
  Returns a client struct or nil
  """
  @callback get_client(String.t) :: struct # or nil

  @doc """
  Registers a client
  Returns {:ok, client_struct} or {:error, error_struct}
  """
  @callback register_client(Map.t) :: {:ok, any}

  ## END Client Behaviours

  ## START ClientAuthorization Behaviours

  @doc """
  Grants a client authorization to a user's account, for a specified scope

  Returns {:ok, client_authorization_struct}
       or {:error, %{error: :error_message}}

  If authorization has already been granted, it just updates the scope of the authorization

  Client Authorization struct is expected to have the following attributes:
    - client_id of the client that has been granted authorization
    - user_id of the user who the client is granted authorization to
    - scope, a list of scopes the client has been granted

  ## Examples

      iex> Ollo.ClientAuthModule.grant_authorization(%{client_id: "client-id", user_id: "user-id", scope: ["read", "write"]})
      {:ok, %ClientAuthorization{client_id: "client-id", user_id: "user-id", scope: ["read", "write"]}}

  """
  @callback grant_authorization(Map.t) :: {:ok, struct}

  ## END ClientAuthorization Behaviours

  ## START User Behaviours

  @doc """
  Gets a user by their email
  Returns a user struct or nil
  """
  @callback get_user_by_email(String.t) :: struct # or nil

  @doc """
  Checks if a user's password matches the given unencrypted password
  Returns true or false

  Allows the Ollo-user to define their own password encryption
  """
  @callback match_pw(struct, String.t) :: boolean

  ## END User Behaviours

  ## START Token Behaviours

  @doc """
  Creates a token
  Returns a Token struct, raises an error if something creation fails

  Token struct must have the following attributes:
    - value (string)
    - token_type
    - user_id (string or UUID or integer)
    - client_id (string or UUID or integer)
    - expires_at (datetime)
  """
  @callback create_token!(Map.t) :: struct

  @doc """
  Gets a token based on the token_type (atom) and value (String)
  Returns a Token struct or nil
  """
  @callback get_token(atom, String.t) :: struct

  ## END Token Behaviours
end
