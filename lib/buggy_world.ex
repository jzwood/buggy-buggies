defmodule BuggyWorld do
  use GenServer
  require EvolveWorld

  # Client
  def start_link(world) when is_map(world) do
    GenServer.start_link(__MODULE__, world)
  end

  def take_turn(pid, handle, movement) do
    GenServer.call(pid, {:move, %{player: handle, action: %{move: movement}}})
  end

  def get_world(pid) do
    GenServer.call(pid, :noop)
  end

  # Server (callbacks)
  @impl true
  def init(world) do
    {:ok, world}
  end

  @impl true
  def handle_call(:noop, _from, world) do
    {:reply, world, world}
  end

  def handle_call({:move, %{player: handle, action: %{move: movement}} = action}, _from, world) do
    case EvolveWorld.next_world({:world, world}, action) do
      {:ok, client_world, server_world} -> {:reply, {:ok, client_world}, server_world}
      err  -> {:reply, err, world}
    end
  end
end
