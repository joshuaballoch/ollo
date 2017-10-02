defmodule Ollo.Config do
  @moduledoc """
  Ollo configuration module
  """

  [
    :client_module,
    :user_module
  ]
  |> Enum.each(fn
    {key, default} ->
      def unquote(key)(opts \\ unquote(default)) do
        Application.get_env(:ollo, unquote(key), opts)
      end
    key ->
      def unquote(key)(opts \\ nil) do
        Application.get_env(:ollo, unquote(key), opts)
      end
  end)
end
