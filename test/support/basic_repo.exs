defmodule BasicRepo do
  use Agent

  def start_link(name) do
    Agent.start_link(fn -> %{} end, name: name)
  end

  def get(name, key) do
    Agent.get(name, &Map.get(&1, key))
  end

  def insert(name, key, value) do
    Agent.update(name, &Map.put(&1, key, value))
  end
end
