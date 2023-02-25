defmodule LiveBuggies.GameManager do
  use GenServer
  alias LiveBuggiesWeb.{LiveWorld, LiveWorlds}

  @worlds CreateWorlds.get_ascii_worlds() |> CreateWorlds.create_worlds() |> Enum.reverse()

  def get_name(game_id) do
    {:via, Registry, {:game_registry, game_id}}
  end

  defp get_game(game_id) when is_binary(game_id) do
    with [{pid, nil}] <- Registry.lookup(:game_registry, game_id) do
      {:ok, pid}
    end
  end

  def host(handle: handle) do
    game_id = UUID.uuid4()
    world = hd(@worlds)

    secret = UUID.uuid4()

    {x, y} = World.random_spawn(world)

    game = %Game{
      world: world,
      host_secret: secret,
      players: %{secret => %Player{handle: handle, x: x, y: y}}
    }

    # LiveWorlds.update_world_list(Map.keys(state.games))
     example = "curl -X GET http://localhost:4000/api/game/#{game_id}/player/#{secret}/move/N"

    GenServer.start(__MODULE__, game, name: get_name(game_id))

    %{game_id: game_id, secret: secret, example: example}
  end

  # return %{secret: uuid, unix time game start}
  def join(game_id: game_id, handle: handle) do
    with {:ok, pid} <- get_game(game_id) do
      GenServer.call(pid, {:join, game_id, handle})
    end
  end

  def start_game(game_id: game_id, secret: secret) do
    with {:ok, pid} <- get_game(game_id) do
      GenServer.call(pid, {:start, game_id, secret})
    end
  end

  def info(game_id) do
    GenServer.call(get_name(game_id), :info)
  end

  def list_games() do
    Registry.select(:game_registry, [{{:"$1", :_, :_}, [], [:"$1"]}])
  end

  def move(game_id: game_id, secret: secret, move: move) do
    GenServer.call(__MODULE__, {:move, game_id, secret, move})
  end

  # Callbacks
  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:host, handle}, _from, %State{} = state) do
    game_id = UUID.uuid4()
    world = hd(@worlds)
    secret = UUID.uuid4()

    {x, y} = World.random_spawn(world)

    game = %Game{
      world: world,
      host_secret: secret,
      players: %{secret => %Player{handle: handle, x: x, y: y}}
    }

    state = State.upsert_game(state, game_id, game) |> IO.inspect(label: "HOST")

    LiveWorlds.update_world_list(Map.keys(state.games))

    example = "curl -X GET http://localhost:4000/api/game/#{game_id}/player/#{secret}/move/N"

    {:reply, {:ok, %{game_id: game_id, secret: secret, example: example}}, state}
  end

  @impl true
  def handle_call(:list_games, _from, state) do
    {:reply, Map.keys(state.games), state}
  end

  @impl true
  def handle_call({:join, game_id, handle}, _from, %State{} = state) do
    # prevent users with the same handle from joining
    with {:ok, game} <- State.fetch_game(state, game_id) do
      secret = UUID.uuid4()

      {x, y} = World.random_spawn(game.world)
      new_game = Game.upsert_player(game, secret, %Player{handle: handle, x: x, y: y})

      new_state = State.upsert_game(state, game_id, new_game)
      {:reply, {:ok, secret}, new_state}
    else
      err -> {:reply, err, state}
    end
  end

  @impl true
  def handle_call({:start, game_id, secret}, _from, %State{} = state) do
    with {:ok, game} <- State.fetch_game(state, game_id),
         {:ok, new_game} <- Game.start(game, secret) do
      new_state = State.upsert_game(state, game_id, new_game)
      {:reply, :ok, new_state}
    else
      err -> {:reply, err, state}
    end
  end

  @impl true
  def handle_call(:info, _from, game) do
    {:reply, game, game}
  end

  @impl true
  def handle_call({:move, game_id, secret, move}, _from, %State{} = state) do
    with {:ok, game} <- State.fetch_game(state, game_id),
         {:ok, player} <- Game.fetch_player(game, secret),
         {:ok, world, player} <- World.next_world(world: game.world, player: player, move: move) do
      new_game = Game.upsert_world(game, world)
      new_game = Game.upsert_player(new_game, secret, player)
      new_state = State.upsert_game(state, game_id, new_game)

      LiveWorld.update_world(game_id: game_id, game: new_game)

      {:reply, {:ok, world, player}, new_state}
    else
      err -> {:reply, err, state}
    end
  end
end
