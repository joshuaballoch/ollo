ExUnit.start()

Code.require_file "./support/basic_repo.exs", __DIR__
Code.require_file "./support/test_persistence_module.exs", __DIR__

Application.put_env(:ollo, :persistence_module, Ollo.TestPersistenceModule)
Ollo.TestPersistenceModule.start
