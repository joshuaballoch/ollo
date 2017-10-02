defmodule BasicRepo do
  use Agent

  def start_link(name) do
    Agent.start_link(fn -> %{} end, name: name)
  end

  def get(name, key) do
    Agent.get(name, &Map.get(&1, key))
  end

  def get_by(name, key, val) do
    values = Agent.get(name, &Map.values(&1))
    IO.inspect(values)
    Enum.find(values, fn value ->
      Map.get(value, key) == val
    end)
  end

  def insert(name, key, value) do
    Agent.update(name, &Map.put(&1, key, value))
  end
end
