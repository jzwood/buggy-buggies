defmodule LiveBuggies.GameManager do
  use GenServer
  alias LiveBuggiesWeb.{LiveWorld, LiveWorlds}

  @worlds CreateWorlds.get_ascii_worlds() |> CreateWorlds.create_worlds() |> Enum.reverse()

  defp get_name(game_id), do: {:via, Registry, {:game_registry, game_id}}

  defp genserver_call(game_id, args) do
    name = get_name(game_id)
    case GenServer.whereis(name) do
      nil -> :error
      _ -> GenServer.call(name, args)
    end
  end

  def host(handle: handle) do
    game_id = UUID.uuid4()
    world = hd(@worlds)
    secret = UUID.uuid4()

    {x, y} = World.random_spawn(world)

    game = %Game{
      id: game_id,
      world: world,
      host_secret: secret,
      players: %{secret => %Player{handle: handle, x: x, y: y}}
    }

    example = "curl -X GET http://localhost:4000/api/game/#{game_id}/player/#{secret}/move/N"

    GenServer.start(__MODULE__, game, name: get_name(game_id))
    LiveWorlds.update_world_list(list_games())

    {:ok, %{game_id: game_id, secret: secret, example: example}}
  end

  # return %{secret: uuid, unix time game start}
  def join(game_id: game_id, handle: handle) do
    genserver_call(game_id, {:join, handle})
  end

  def start_game(game_id: game_id, secret: secret) do
    genserver_call(game_id, {:start_game, secret})
  end

  def info(game_id: game_id) do
    genserver_call(game_id, :info)
  end

  def list_games() do
    Registry.select(:game_registry, [{{:"$1", :_, :_}, [], [:"$1"]}])
  end

  def move(game_id: game_id, secret: secret, move: move) do
    genserver_call(game_id, {:move, secret, move})
  end

  def game_over(game_id: game_id) do
    genserver_call(game_id, :game_over)
  end

  # Callbacks
  @impl true
  def init(game) do
    {:ok, game}
  end

  @impl true
  def handle_call({:join, handle}, _from, %Game{} = game) do
    # TODO prevent users with the same handle from joining
    secret = UUID.uuid4()
    game = Game.add_player(game, handle: handle, secret: secret)
    {:reply, {:ok, secret}, game}
  end

  @impl true
  def handle_call({:start_game, secret}, _from, %Game{} = game) do
    with {:ok, game} <- Game.start(game, secret) do
      {:reply, :ok, game}
    else
      err -> {:reply, err, game}
    end
  end

  @impl true
  def handle_call(:info, _from, game) do
    {:reply, game, game}
  end

  @impl true
  def handle_call({:move, secret, move}, _from, %Game{} = game) do
    with {:ok, player} <- Game.fetch_player(game, secret),
         {:ok, world, player} <- World.next_world(world: game.world, player: player, move: move) do
      game =
        game
        |> Game.upsert_world(world)
        |> Game.upsert_player(secret, player)

      player_game = CreateWorlds.get_player_game(game, player)
      LiveWorld.update_game(game: game)

      {:reply, {:ok, player_game}, game}
    else
      err -> {:reply, err, game}
    end
  end

  @impl true
  def handle_cast(:game_over, game) do
    {:stop, :game_over, game}
  end
end
