defmodule Ollo.InMemoryTokenModule do

  @repo_name :token_repo

  def start_repo do
    {:ok, _pid } = BasicRepo.start_link(@repo_name)
  end

  defmodule Token do
    defstruct [:id, :value, :user_id, :client_id, :token_type]
  end

  def get_by_value(email) do
    BasicRepo.get_by(@repo_name, :email, email)
  end

  def create_token!(%{user_id: _, client_id: _, value: _, token_type: _} = params) do
    id = "id-#{:rand.uniform(10000)}"
    Map.put(params, :id, id)
    BasicRepo.insert(@repo_name, id, params)
    params
  end

  def get_token(token_type, value) do
    case BasicRepo.get_by(@repo_name, :value, value) do
      nil -> nil
      token ->
        if token.token_type == Atom.to_string(token_type) do
          token
        else
          nil
        end
    end
  end
end

