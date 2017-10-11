defmodule Ollo do
  @moduledoc """
  Ollo: Oauth2 Provider
  """
  import Ollo.Helpers, [:verify_and_get_client, :verify_scopes]

  alias Ollo.Config

  @doc """
  Gets the client matching the client_id
  Returns a client struct OR nil
  """
  def get_client(client_id) do
    Config.persistence_module.get_client(client_id)
  end

  @doc """
  Registers a client
  Returns {:ok, client_struct} or {:error, error_struct}
  """
  def register_client(%{name: name} = argv) do
    Config.persistence_module.register_client(argv)
  end

  @doc """
  Gets temporary code(s) for use in different Oauth flows
  Returns a struct with those codes, depending on the flow in question

  In the case of the authorization_code grant (yet to be implemented), this will
  implicitly grant authorization to the user's account to the client

  ### Examples

       iex> Ollo.get_temp_code(:device_flow, %{client_id: "some-client-id", scopes: ["read"]})
       {:ok, %{device_code: "device-code", user_code: "user-code", expires_in: 3600}}

  """
  def get_temp_code(grant_type, params) do
    Map.get(Ollo.Config.enabled_grants, grant_type).get_temp_code(params)
  end

  @doc """
  Gets information about the client and scope requested
  Returns a struct representing info about the request, or nil
  """
  def get_temp_code_info(:device_flow, code) do
    Ollo.GrantTypes.DeviceFlow.get_temp_code_info(code)
  end

  @doc """
  Grants authorization to a user's account to a client
  Returns {:ok, client_auth} or {:error, %{error: :error_atom}}

  Verifies client_id is a valid client, and the scopes are in the allowed scopes

  Does not verify the user_id
  """
  def grant_client_authorization(%{client_id: _, user_id: _, scopes: _} = params) do
    params
    |> verify_and_get_client
    |> verify_scopes
    |> create_client_authorization
  end
  def grant_client_authorization(:device_flow, %{user_code: user_code, user_id: user_id} = params) do
    Ollo.GrantTypes.DeviceFlow.grant_authorization(%{code: user_code, user_id: user_id})
  end


  @doc """
  Checks if a client has authorization to perform a certain scope
  On a user's account

  Accepts a user_id, client_id, and scope

  Returns true or false
  """
  def authorized?(%{client_id: client_id, user_id: user_id, scope: scope}) do
    case Ollo.Config.persistence_module.get_client_authorization(client_id: client_id, user_id: user_id) do
      nil -> false
      client_auth -> Enum.any? client_auth.scopes, fn (s) -> s == scope end
    end
  end

  @doc """
  (Device Flow Only)
  Rejects a request for authorization by a client

  ### Examples

        iex> Ollo.reject_temp_code(:device_flow, "user-code")
        {:ok, %{}}

        iex> Ollo.reject_temp_code(:device_flow, "nonexistent-user-code")
        {:error, %{error: :invalid_user_code}}

  """
  def reject_temp_code(:device_flow, code) do
    Map.get(Ollo.Config.enabled_grants, :device_flow).reject_temp_code(code)
  end

  @doc """
  Gets refresh and access tokens (the last step of any grant)
  Returns {:ok, {refresh: refresh_token, access: access_token}}
       or {:error, %{error: error_atom}}
  """
  def get_tokens(grant_type, params) do
    Map.get(Ollo.Config.enabled_grants, grant_type).get_tokens(params)
  end

  ## Private Methods

  ### START For grant_client_authorization
  defp create_client_authorization({:error, res}), do: {:error, res}
  defp create_client_authorization({:ok, %{client_id: client_id, user_id: user_id, scopes: scopes}}) do
    Ollo.Config.persistence_module.grant_authorization(%{
      client_id: client_id,
      user_id: user_id,
      scopes: scopes
    })
  end
  ### END For grant_client_authorization
end
