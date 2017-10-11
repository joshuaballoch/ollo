defmodule Ollo.InMemoryClientAuthModule do

  @repo_name :client_auth_repo

  def start_repo do
    {:ok, _pid } = BasicRepo.start_link(@repo_name)
  end

  defmodule ClientAuthorization do
    defstruct [:client_id, :user_id, :scopes]
  end

  def grant_authorization(%{client_id: client_id, user_id: user_id, scopes: scopes} = params) do
    client_auth = %ClientAuthorization{
      client_id: client_id,
      user_id: user_id,
      scopes: scopes
    }
    BasicRepo.insert(@repo_name, :rand.uniform(100000), client_auth)
    {:ok, client_auth}
  end

  def get_client_authorization(client_id: client_id, user_id: user_id) do
    BasicRepo.get_by(@repo_name, client_id: client_id, user_id: user_id)
  end
end

