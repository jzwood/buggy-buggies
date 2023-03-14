defmodule LiveBuggies.GameManager do
  use GenServer
  alias LiveBuggiesWeb.{LiveWorld, LiveWorlds}

  @worlds CreateWorlds.get_ascii_worlds() |> CreateWorlds.create_worlds() |> Enum.reverse()

  defp get_name(game_id), do: {:via, Registry, {:game_registry, game_id}}

  defp genserver_call(game_id, args) do
    name = get_name(game_id)

    case GenServer.whereis(name) |> IO.inspect(label: "HERE") do
      pid when is_pid(pid) -> GenServer.call(name, args)
      _ -> :error
    end
  end

  def host(handle: handle) do
    game_id = UUID.uuid4()
    world = hd(@worlds)
    secret = UUID.uuid4()

    {x, y} = World.random_empty(world)

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

  def join(game_id: game_id, handle: handle) do
    genserver_call(game_id, {:join, handle})
  end

  # def start_game(game_id: game_id, secret: secret) do
  # genserver_call(game_id, {:start_game, secret})
  # end

  def debug(game_id: game_id) do
    genserver_call(game_id, :debug)
  end

  def list_games() do
    Registry.select(:game_registry, [{{:"$1", :_, :_}, [], [:"$1"]}])
  end

  def move(game_id: game_id, secret: secret, move: move) do
    genserver_call(game_id, {:move, secret, move})
  end

  def info(game_id: game_id, secret: secret) do
    genserver_call(game_id, {:info, secret})
  end

  def kill(game_id: game_id) do
    name = get_name(game_id)

    with pid when is_pid(pid) <- GenServer.whereis(name),
         :ok <- GenServer.stop(name) do
      LiveWorlds.update_world_list(list_games())
      :ok
    else
      _ -> :error
    end
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
    %Game{id: game_id} = game = Game.add_player(game, handle: handle, secret: secret)

    LiveWorld.update_game(game: game)
    example = "curl -X GET http://localhost:4000/api/game/#{game_id}/player/#{secret}/move/N"

    {:reply, {:ok, %{game_id: game_id, secret: secret, example: example}}, game}
  end

  @impl true
  def handle_call(:debug, _from, game) do
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
  def handle_call({:info, secret}, _from, %Game{} = game) do
    with {:ok, player} <- Game.fetch_player(game, secret) do
      player_game = CreateWorlds.get_player_game(game, player)
      {:reply, {:ok, player_game}, game}
    else
      err -> {:reply, err, game}
    end
  end
end
