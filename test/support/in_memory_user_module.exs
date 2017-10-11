defmodule Ollo.InMemoryUserModule do

  @repo_name :user_repo

  def start_repo do
    {:ok, _pid } = BasicRepo.start_link(@repo_name)
  end

  defmodule User do
    defstruct [:id, :email, :password]
  end

  def get_user_by_email(email) do
    BasicRepo.get_by(@repo_name, email: email)
  end

  def match_pw(user, password) do
    user.password == password
  end

  def insert_user(%{email: email, password: password}) do
    user_id = "user-id-#{:rand.uniform(10000)}"
    user = %User{
      id: user_id,
      email: email,
      password: password
    }
    BasicRepo.insert(@repo_name, user_id, user)
    {:ok, user}
  end
end

