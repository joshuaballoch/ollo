defmodule Ollo.Config do
  @moduledoc """
  Ollo configuration module
  """

  @token_expiry_defaults quote do: %{
    refresh: 7 * 24,
    access: 24
  }

  [
    {:token_expiry_in_hours, @token_expiry_defaults},
    {:allowed_scopes, []},
    :client_auth_module,
    :client_module,
    :user_module,
    :token_module
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
