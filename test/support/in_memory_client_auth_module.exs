defmodule Ollo.InMemoryClientAuthModule do
  @behaviour Ollo.ClientAuthModule

  @repo_name :client_auth_repo

  def start_repo do
    {:ok, _pid } = BasicRepo.start_link(@repo_name)
  end

  defmodule ClientAuthorization do
    defstruct [:client_id, :user_id, :scope]
  end

  def grant_authorization(%{client_id: client_id, user_id: user_id, scope: scope}) do
    client_auth = %ClientAuthorization{
      client_id: client_id,
      user_id: user_id,
      scope: scope
    }
    BasicRepo.insert(@repo_name, :rand.uniform(100000), client_auth)
    {:ok, client_auth}
  end
end

