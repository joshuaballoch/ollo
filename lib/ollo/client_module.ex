defmodule Ollo.ClientModule do
  @moduledoc """
  Behaviour-spec for user-defined client module
  """

  @callback get_client(String.t) :: any
  @callback register_client(Map.t) :: {:ok, any}
end
