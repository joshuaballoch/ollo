defmodule Ollo.GrantTypes.DeviceFlow do
  @moduledoc """
  """
  import Ollo.Helpers, [:verify_and_get_client, :verify_scopes, :create_tokens!]

  @doc """
  Gets device and user codes to use during authorization process
  Returns a struct with the device, user codes and their expiry
  """
  def get_temp_code(%{client_id: client_id, scopes: scopes} = params) do
    params
    |> verify_and_get_client
    |> verify_scopes
    |> create_device_and_user_codes
  end

  def get_temp_code_info(user_code) do
    %{code: user_code}
    |> get_user_token
    |> get_matching_device_token
    |> return_temp_code_info
  end

  def return_temp_code_info({:error, res}), do: nil
  def return_temp_code_info({:ok, %{device_token: device_token}}) do
    client = Ollo.get_client(device_token.client_id)
    %{
      client: client,
      status: device_token.status,
      requested_scopes: device_token.requested_scopes
    }
  end


  def grant_authorization(%{user_id: user_id, code: code} = params) do
    params
    |> get_user_token
    |> get_matching_device_token
    |> grant_authorization
    |> update_device_token_to_granted
  end
  def grant_authorization({:error, res}), do: {:error, res}
  def grant_authorization({:ok, %{device_token: device_token, user_id: user_id}}) do
    res = Ollo.grant_client_authorization(%{
      client_id: device_token.client_id,
      user_id: user_id,
      scopes: device_token.requested_scopes
    })

    case res do
      {:error, res} -> {:error, res}
      {:ok, res} -> {:ok, %{user_result: res, device_token: device_token, user_id: user_id}}
    end
  end

  def reject_temp_code(code) do
    case Ollo.Config.persistence_module.get_token(:user_code, code) do
      nil -> {:error, %{error: :invalid_user_code}}
      user_token ->
        device_token = Ollo.Config.persistence_module.get_token(:device_code, user_token.parent_token_value)
        Ollo.Config.persistence_module.update_token(device_token, %{status: "rejected"})
        {:ok, %{}}
    end
  end

  @doc """
  Gets access and refresh tokens for a device_code that has been approved.
  Returns a struct with access, refresh tokens and their expiry

  Also can return an error struct with information of the state of the authorization
  """
  def get_tokens(%{client_id: _, code: _} = params) do
    params
    |> verify_and_get_client
    |> verify_and_get_device_token
    |> check_device_token_expiry
    |> check_device_status_granted
    |> generate_tokens
    |> delete_temp_codes
  end

  defp create_device_and_user_codes({:error, res}), do: {:error, res}
  defp create_device_and_user_codes({:ok, %{client: client, scopes: scopes} = params}) do
    device_token = create_token!(:device_code, %{client_id: client.client_id, status: "pending", requested_scopes: scopes})
    user_token = create_token!(:user_code, %{client_id: client.client_id, parent_token_value: device_token.value})
    expires_in = DateTime.to_unix(user_token.expires_at) - (DateTime.utc_now |> DateTime.to_unix)
    {:ok, %{
      device_code: device_token.value,
      user_code: user_token.value,
      expires_in: expires_in}}
  end

  defp verify_and_get_device_token({:error, res}), do: {:error, res}
  defp verify_and_get_device_token({:ok, %{code: code, client_id: client_id} = params}) do
    case Ollo.Config.persistence_module.get_token(:device_code, code) do
      nil -> {:error, %{error: :invalid_device_code}}
      token ->
        case token.client_id == client_id do
          false -> {:error, %{error: :invalid_device_code}}
          true -> {:ok, Map.put(params, :device_token, token)}
        end
    end
  end

  defp check_device_token_expiry({:error, res}), do: {:error, res}
  defp check_device_token_expiry({:ok, %{device_token: device_token} = params}) do
    now = DateTime.utc_now |> DateTime.to_unix
    case DateTime.to_unix(device_token.expires_at) < now do
      false -> {:ok, params}
      true -> {:error, %{error: :expired_grant}}
    end
  end

  defp check_device_status_granted({:error, res}), do: {:error, res}
  defp check_device_status_granted({:ok, %{device_token: device_token} = params}) do
    case device_token.status do
      "pending" -> {:error, %{error: :pending}}
      "rejected" -> {:error, %{error: :rejected}}
      "granted" -> {:ok, params}
    end
  end

  defp get_user_token(%{code: code} = params) do
    case Ollo.Config.persistence_module.get_token(:user_code, code) do
      nil -> {:error, %{error: :invalid_user_code}}
      token -> {:ok, Map.put(params, :user_token, token)}
    end
  end

  defp get_matching_device_token({:error, res}), do: {:error, res}
  defp get_matching_device_token({:ok, %{user_token: user_token} = params}) do
    device_token = Ollo.Config.persistence_module.get_token(:device_code, user_token.parent_token_value)
    {:ok, Map.put(params, :device_token, device_token)}
  end

  defp update_device_token_to_granted({:error, res}), do: {:error, res}
  defp update_device_token_to_granted({:ok, %{user_result: user_result, device_token: device_token, user_id: user_id}}) do
    Ollo.Config.persistence_module.update_token(device_token, %{status: "granted", user_id: user_id})
    {:ok, user_result}
  end

  defp generate_tokens({:error, res}), do: {:error, res}
  defp generate_tokens({:ok, %{client_id: client_id, device_token: device_token}}) do
    tokens = create_tokens!([:refresh, :access], %{user_id: device_token.user_id, client_id: client_id})
    {:ok, %{tokens: tokens, device_token: device_token}}
  end

  defp delete_temp_codes({:error, res}), do: {:error, res}
  defp delete_temp_codes({:ok, %{tokens: tokens, device_token: device_token}}) do
    Ollo.Config.persistence_module.get_token_by(:user_code, %{parent_token_value: device_token.value})
    |> Ollo.Config.persistence_module.delete_token!
    Ollo.Config.persistence_module.delete_token!(device_token)
    {:ok, %{tokens: tokens}}
  end
end
