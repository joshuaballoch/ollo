defmodule Ollo.Helpers do

  def verify_and_get_client(%{client_id: client_id} = params) do
    case Ollo.get_client(client_id) do
      nil -> {:error, %{error: :invalid_client_id}}
      client -> {:ok, Map.put(params, :client, client)}
    end
  end

  def verify_scopes({:error, res}), do: {:error, res}
  def verify_scopes({:ok, %{scopes: requested_scopes} = params}) do
    case Enum.all?(requested_scopes, fn scope -> Enum.member?(Ollo.Config.allowed_scopes, scope) end) do
      false -> {:error, %{error: :invalid_scope}}
      true -> {:ok, params}
    end
  end

  def create_tokens!(token_types, %{client_id: client_id} = params) do
    Enum.map token_types, fn token_type ->
      token = create_token!(token_type, params)
      {token_type, token}
    end
  end

  def create_token!(token_type, %{client_id: client_id} = params) do
    time_now = DateTime.utc_now |> DateTime.to_unix
    expires_at = DateTime.from_unix!(time_now + round(Map.get(Ollo.Config.token_expiry_in_hours, token_type) * 3600))
    %{
      user_id: params[:user_id],
      client_id: client_id,
      token_type: Atom.to_string(token_type),
      expires_at: expires_at,
      status: params[:status],
      parent_token_value: params[:parent_token_value],
      requested_scopes: params[:requested_scopes]
    }
    |> put_token_value
    |> Ollo.Config.persistence_module.create_token!
  end

  defp put_token_value(token_struct) do
    Map.put(token_struct, :value, SecureRandom.urlsafe_base64)
  end
end
