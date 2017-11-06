defmodule Ollo.GrantTypes.RefreshToken do
  import Ollo.Helpers

  def get_tokens(%{code: _, client_id: _} = argv) do
    argv
    |> get_client
    |> get_refresh_token
    |> check_client_id_match
    |> check_token_expiry
    |> generate_tokens
    |> delete_prior_refresh_token
  end

  defp get_client(%{client_id: client_id} = params) do
    case Ollo.Config.persistence_module.get_client(client_id) do
      nil -> {:error, %{error: :invalid_client_id}}
      _ -> {:ok, params}
    end
  end

  defp get_refresh_token({:error, res}), do: {:error, res}
  defp get_refresh_token({:ok, %{code: code} = params}) do
    case Ollo.Config.persistence_module.get_token(:refresh, code) do
      nil   -> {:error, %{error: :invalid_token}}
      token -> {:ok,    Map.put(params, :refresh_token, token)}
    end
  end

  defp check_token_expiry({:error, res}), do: {:error, res}
  defp check_token_expiry({:ok, %{refresh_token: refresh_token} = params}) do
    case DateTime.compare(refresh_token.expires_at, DateTime.utc_now) do
      :lt -> {:error, %{error: :expired_token}}
      :gt -> {:ok, params}
    end
  end

  defp check_client_id_match({:error, res}), do: {:error, res}
  defp check_client_id_match({:ok, %{refresh_token: refresh_token, client_id: client_id} = params}) do

    case refresh_token.client_id == client_id do
      false -> {:error, %{error: :invalid_token}}
      true  -> {:ok, params}
    end
  end

  defp generate_tokens({:error, res}), do: {:error, res}
  defp generate_tokens({:ok, %{refresh_token: refresh_token, client_id: client_id}}) do
    tokens = create_tokens!([:refresh, :access], %{user_id: refresh_token.user_id, client_id: client_id})
    {:ok, %{tokens: tokens, refresh_token: refresh_token}}
  end

  defp delete_prior_refresh_token({:error, res}), do: {:error, res}
  defp delete_prior_refresh_token({:ok, %{tokens: tokens, refresh_token: refresh_token}}) do
    Ollo.Config.persistence_module.delete_token!(refresh_token)
    {:ok, %{tokens: tokens}}
  end
end
