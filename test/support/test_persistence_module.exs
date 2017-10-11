Code.require_file "../support/in_memory_client_auth_module.exs", __DIR__
Code.require_file "../support/in_memory_client_module.exs", __DIR__
Code.require_file "../support/in_memory_user_module.exs", __DIR__
Code.require_file "../support/in_memory_token_module.exs", __DIR__

defmodule Ollo.TestPersistenceModule do
  @behaviour Ollo.PersistenceModule

  def start do
    Ollo.InMemoryClientAuthModule.start_repo
    Ollo.InMemoryClientModule.start_repo
    Ollo.InMemoryUserModule.start_repo
    Ollo.InMemoryTokenModule.start_repo
  end

  def register_client(%{name: name} = params) do
    Ollo.InMemoryClientModule.register_client(params)
  end

  def get_client(client_id) do
    Ollo.InMemoryClientModule.get_client(client_id)
  end

  def grant_authorization(%{client_id: _, user_id: _, scopes: _} = params) do
    Ollo.InMemoryClientAuthModule.grant_authorization(params)
  end

  def get_client_authorization(client_id: client_id, user_id: user_id) do
    Ollo.InMemoryClientAuthModule.get_client_authorization(client_id: client_id, user_id: user_id)
  end

  def get_user_by_email(email) do
    Ollo.InMemoryUserModule.get_user_by_email(email)
  end

  def match_pw(user, password) do
    Ollo.InMemoryUserModule.match_pw(user, password)
  end

  def create_token!(%{value: _, user_id: _, client_id: _, expires_at: _, token_type: _} = params) do
    Ollo.InMemoryTokenModule.create_token!(params)
  end

  def get_token(token_type, value) do
    Ollo.InMemoryTokenModule.get_token(token_type, value)
  end

  def get_token_by(token_type, params) do
    Ollo.InMemoryTokenModule.get_token_by(token_type, params)
  end

  def update_token(token, params) do
    Ollo.InMemoryTokenModule.update_token(token, params)
  end

  def delete_token!(token) do
    Ollo.InMemoryTokenModule.delete_token!(token)
  end
end

