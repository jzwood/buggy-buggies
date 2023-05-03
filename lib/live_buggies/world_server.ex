defmodule LiveBuggies.WorldServer do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def get(root) do
    GenServer.call(__MODULE__, {:get, root})
  end

  def all() do
    GenServer.call(__MODULE__, :all)
  end

  def random() do
    GenServer.call(__MODULE__, :random)
  end

  @impl true
  def init(_) do
    worlds = CreateWorlds.create_worlds()
    {:ok, worlds}
  end

  @impl true
  def handle_call({:get, root}, _from, worlds) do
    {:reply, Map.get(worlds, root), worlds}
  end

  @impl true
  def handle_call(:all, _from, worlds) do
    {:reply, worlds, worlds}
  end

  @impl true
  def handle_call(:random, _from, worlds) do
    rand_key =
      worlds
      |> Map.keys()
      |> Enum.random()

    rand_world = Map.get(worlds, rand_key)
    {:reply, {rand_key, rand_world}, worlds}
  end
end
