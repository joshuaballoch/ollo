defmodule Ollo.Helpers do

  def create_tokens!(tokens: token_types, user_id: user_id, client_id: client_id) do
    Enum.map token_types, fn token_type ->
      token = create_token!(token_type, client_id: client_id, user_id: user_id)
      {token_type, token}
    end
  end

  def create_token!(token_type, client_id: client_id, user_id: user_id) do
    time_now = DateTime.utc_now |> DateTime.to_unix
    expires_at = DateTime.from_unix!(time_now + Map.get(Ollo.Config.token_expiry_in_hours, token_type) * 3600)
    %{
      user_id: user_id,
      client_id: client_id,
      token_type: Atom.to_string(token_type),
      expires_at: expires_at
    }
    |> put_token_value
    |> Ollo.Config.persistence_module.create_token!
  end

  defp put_token_value(token_struct) do
    Map.put(token_struct, :value, SecureRandom.urlsafe_base64)
  end
end
