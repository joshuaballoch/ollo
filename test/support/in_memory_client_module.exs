defmodule Ollo.InMemoryClientModule do

  @repo_name :client_repo

  def start_repo do
    {:ok, _pid } = BasicRepo.start_link(@repo_name)
  end

  defmodule Client do
    defstruct [:name, :client_id]
  end

  def get_client(client_id) do
    BasicRepo.get(@repo_name, client_id)
  end

  def register_client(%{name: name} = params) do
    client_id = "client-id-#{:rand.uniform(10000)}"
    client = %Client{
      name: name,
      client_id: client_id
    }
    BasicRepo.insert(@repo_name, client_id, client)
    {:ok, client}
  end
end

