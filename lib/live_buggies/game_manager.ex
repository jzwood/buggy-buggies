defmodule LiveBuggies.GameManager do
  use GenServer

  @init_state %State{}
  @worlds CreateWorlds.get_ascii_worlds() |> CreateWorlds.create_worlds() |> Enum.reverse()
  @world_list_topic "worlds"

  # Public API
  def start_link(_args) do
    GenServer.start_link(__MODULE__, @init_state, name: __MODULE__)
  end

  # return %{game_id: uuid, secret: uuid}
  # pass in world_id at some point
  def host(handle: handle) do
    GenServer.call(__MODULE__, {:host, handle})
  end

  # return %{secret: uuid, unix time game start}
  def join(game_id: game_id, handle: handle) do
    GenServer.call(__MODULE__, {:join, game_id, handle})
  end

  def start(game_id: game_id, secret: secret) do
    GenServer.call(__MODULE__, {:start, game_id, secret})
  end

  def info(game_id: game_id) do
    GenServer.call(__MODULE__, {:info, game_id})
  end

  def list_worlds() do
    GenServer.call(__MODULE__, :list_worlds)
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

    game = %Game{
      world: world,
      host_secret: secret,
      players: %{secret => %Player{handle: handle, x: 0, y: 0}}
    } |> IO.inspect(label: "H1")

    state = State.upsert_game(state, game_id, game) |> IO.inspect(label: "HOST")

    LiveBuggiesWeb.LiveWorlds.update_world_list(Map.keys(state.games))

    {:reply, {:ok, %{game_id: game_id, secret: secret}}, state}
  end

  @impl true
  def handle_call(:list_worlds, _from, state) do
    {:reply, Map.keys(state.games), state}
  end

  @impl true
  def handle_call({:join, game_id, handle}, _from, %State{} = state) do
    # prevent users with the same handle from joining
    with {:ok, game} <- State.fetch_game(state, game_id) do
      secret = UUID.uuid4()

      new_game = Game.upsert_player(game, secret, %Player{handle: handle, x: 0, y: 0})

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
  def handle_call({:info, game_id}, _from, %State{} = state) do
    with {:ok, world} <- State.fetch_game(state, game_id) do
      {:reply, world, state}
    else
      err -> {:reply, err, state}
    end
  end

  @impl true
  def handle_call({:move, game_id, secret, move}, _from, %State{} = state) do
    with {:ok, game} <- State.fetch_game(state, game_id),
         {:ok, player} <- Game.fetch_player(game, secret),
         {:ok, world, player} <- World.next_world(world: game.world, player: player, move: move) do
      new_state = State.upsert_game(state, game_id, Game.upsert_world(game, world))
      {:reply, {:ok, world, player}, new_state}
    else
      err -> {:reply, err, state}
    end
  end
end
