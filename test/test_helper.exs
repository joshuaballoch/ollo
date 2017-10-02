ExUnit.start()

Code.require_file "./support/basic_repo.exs", __DIR__
Code.require_file "./support/in_memory_client_module.exs", __DIR__
Code.require_file "./support/in_memory_user_module.exs", __DIR__

Application.put_env(:ollo, :client_module, Ollo.InMemoryClientModule)
Ollo.InMemoryClientModule.start_repo

Application.put_env(:ollo, :user_module, Ollo.InMemoryUserModule)
Ollo.InMemoryUserModule.start_repo
