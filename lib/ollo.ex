defmodule Ollo do
  @moduledoc """
  Ollo: Oauth2 Provider
  """

  alias Ollo.Config

  @doc """
  Gets the client matching the client_id
  Returns a client struct OR nil
  """
  def get_client(client_id) do
    Config.client_module.get_client(client_id)
  end

  @doc """
  Registers a client
  Returns {:ok, client_struct} or {:error, error_struct}
  # TODO: figure out standard error struct?
  """
  def register_client(%{name: name} = argv) do
    Config.client_module.register_client(argv)
  end

  @doc """
  Grants authorization to a user's account to a client
  Returns {:ok, client_auth} or {:error, error_struct}

  Verifies client_id is a valid client, and the scopes are in the allowed scopes

  Does not verify the user_id
  """
  def grant_client_authorization(%{client_id: client_id, user_id: user_id, scope: scope} = params) do
    params
    |> verify_and_get_client
    |> verify_scopes
    |> create_client_authorization
  end

  ## Private Methods

  ### START For grant_client_authorization
  def verify_and_get_client(%{client_id: client_id} = params) do
    case get_client(client_id) do
      nil -> {:error, %{error: :invalid_client_id}}
      client -> {:ok, Map.put(params, :client, client)}
    end
  end

  defp verify_scopes({:error, res}), do: {:error, res}
  defp verify_scopes({:ok, %{scope: requested_scopes} = params}) do
    case Enum.all?(requested_scopes, fn scope -> Enum.member?(Ollo.Config.allowed_scopes, scope) end) do
      false -> {:error, %{error: :invalid_scope}}
      true -> {:ok, params}
    end
  end

  defp create_client_authorization({:error, res}), do: {:error, res}
  defp create_client_authorization({:ok, params}) do
    Ollo.Config.client_auth_module.grant_authorization(params)
  end
  ### END For grant_client_authorization
end
