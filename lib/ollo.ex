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
end
