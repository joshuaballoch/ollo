ExUnit.start()

Code.require_file "./support/basic_repo.exs", __DIR__
Code.require_file "./support/in_memory_client_module.exs", __DIR__

Application.put_env(:ollo, :client_module, Ollo.InMemoryClientModule)
Ollo.InMemoryClientModule.start_repo
