defmodule Cache do
  @moduledoc """
  basic cache
  """
  use GenServer

  # Public API
  def start_link(_args) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def save(key, value) do
    GenServer.cast(__MODULE__, {:save, key, value})
  end

  def lookup(key) do
    GenServer.call(__MODULE__, {:lookup, key})
  end

  # Callbacks
  def init(state) do
    {:ok, state}
  end

  def handle_cast({:save, key, value}, state) do
    updated_map = Map.put(state, key, value)
    {:noreply, updated_map}
  end

  def handle_call({:lookup, key}, _from, state) do
    reply = Map.fetch(state, key)
    {:reply, reply, state}
  end
end
