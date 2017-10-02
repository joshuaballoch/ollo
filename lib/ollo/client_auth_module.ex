defmodule Ollo.ClientAuthModule do
  @moduledoc """
  Behaviour-spec for user-defined client authorization module

  Client Authorization struct is expected to have the following attributes:
    - client_id of the client that has been granted authorization
    - user_id of the user who the client is granted authorization to
    - scope, a list of scopes the client has been granted
  """

  @doc """
  Grants a client authorization to a user's account, for a specified scope

  Returns {:ok, client_authorization_struct}
       or {:error, %{error: :error_message}}

  If authorization has already been granted, it just updates the scope of the authorization

  ## Examples

      iex> Ollo.ClientAuthModule.grant_authorization(%{client_id: "client-id", user_id: "user-id", scope: ["read", "write"]})
      {:ok, %ClientAuthorization{client_id: "client-id", user_id: "user-id", scope: ["read", "write"]}}

  """
  @callback grant_authorization(Map.t) :: {:ok, struct}
end
