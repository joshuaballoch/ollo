defmodule Ollo.GrantTypes.Password do
  import Ollo.Helpers

  def get_tokens(%{email: _, password: _, client_id: _, scopes: _} = argv) do
    argv
    |> get_user
    |> match_email_password
    |> grant_client_authorization
    |> generate_tokens
  end

  defp get_user(%{email: email} = params) do
    case Ollo.Config.persistence_module.get_user_by_email(email) do
      nil  -> {:error, %{error: :invalid_email_password_combo}}
      user -> {:ok,    Map.put(params, :user, user)}
    end
  end

  defp match_email_password({:error, res}), do: {:error, res}
  defp match_email_password({:ok, %{user: user, password: password} = params}) do
    case Ollo.Config.persistence_module.match_pw(user, password) do
      false -> {:error, %{error: :invalid_email_password_combo}}
      true  -> {:ok,    params}
    end
  end

  defp grant_client_authorization({:error, res}), do: {:error, res}
  defp grant_client_authorization({:ok, %{client_id: client_id, user: user, scopes: scopes} = params}) do
    case Ollo.grant_client_authorization(%{client_id: client_id, user_id: user.id, scopes: scopes}) do
      {:error, res} -> {:error, res}
      {:ok, _} -> {:ok, params}
    end
  end

  defp generate_tokens({:error, res}), do: {:error, res}
  defp generate_tokens({:ok, %{client_id: client_id, user: user}}) do
    tokens = create_tokens!([:refresh, :access], %{user_id: user.id, client_id: client_id})
    {:ok, %{tokens: tokens}}
  end
end
