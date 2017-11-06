defmodule Ollo.Config do
  @moduledoc """
  Ollo configuration module
  """

  @token_expiry_defaults quote do: %{
    refresh: 7 * 24,
    access: 24,
    device_code: (10 * 60) / 3600,
    user_code: (10 * 60) / 3600
  }

  @default_grants quote do: %{
    device_flow: Ollo.GrantTypes.DeviceFlow,
    password: Ollo.GrantTypes.Password,
    refresh_token: Ollo.GrantTypes.RefreshToken
  }

  [
    {:allowed_scopes, []},
    {:enabled_grants, @default_grants},
    {:token_expiry_in_hours, @token_expiry_defaults},
    :persistence_module
  ]
  |> Enum.each(fn
    {key, default} ->
      def unquote(key)() do
        Application.get_env(:ollo, unquote(key), unquote(default))
      end
    key ->
      def unquote(key)() do
        Application.get_env(:ollo, unquote(key), nil)
      end
  end)
end
