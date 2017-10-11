defmodule BasicRepo do
  use Agent

  def start_link(name) do
    Agent.start_link(fn -> %{} end, name: name)
  end

  def get(name, key) do
    Agent.get(name, &Map.get(&1, key))
  end

  def get_by(name, attrs) do
    records = Agent.get(name, &Map.values(&1))
    Enum.find(records, fn record ->
      Enum.all? attrs, fn {key, val} ->
        Map.get(record, key) == val
      end
    end)
  end

  def remove_by(name, key, val) do
    Agent.get_and_update(name, fn state ->
      matching_record = Enum.find(state, fn {id, stored_value} ->
        Map.get(stored_value, key) == val
      end)
      id = elem(matching_record, 0)
      {state, Map.delete(state, id)}
    end)
  end

  def insert(name, key, value) do
    Agent.update(name, &Map.put(&1, key, value))
  end
end
