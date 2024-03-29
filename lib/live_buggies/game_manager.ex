defmodule LiveBuggies.GameManager do
  @moduledoc """
  the genserver that manages the gamestate for each game
  """
  use GenServer
  alias LiveBuggiesWeb.{LiveGame, LiveHome}
  alias LiveBuggies.WorldMaps

  defp move_example(game_id: game_id, secret: secret) do
    "curl -X GET #{LiveBuggiesWeb.Endpoint.url()}/api/game/#{game_id}/player/#{secret}/move/N"
  end

  defp spectate_example(game_id: game_id) do
    "#{LiveBuggiesWeb.Endpoint.url()}/game/#{game_id}"
  end

  defp get_name(game_id), do: {:via, Registry, {:game_registry, game_id}}

  defp genserver_call(game_id, args) do
    name = get_name(game_id)

    case GenServer.whereis(name) do
      pid when is_pid(pid) -> GenServer.call(name, args)
      _ -> :error
    end
  end

  def host(handle: handle) do
    host(handle: handle, map: "basic")
  end

  def host(handle: handle, map: map) do
    case WorldMaps.get(map) do
      %{dimensions: dimensions, world: world} ->
        host(handle: handle, dimensions: dimensions, world: world)

      _ ->
        {:error, "map not found"}
    end
  end

  def host(handle: handle, dimensions: dimensions, world: world) do
    game_id = SmallID.new()
    secret = SmallID.new()

    game =
      %Game{
        id: game_id,
        world: world,
        dimensions: dimensions,
        host_secret: secret,
        updated_at: Game.now()
      }
      |> Game.add_player(handle: handle, secret: secret)

    example = move_example(game_id: game_id, secret: secret)
    watch = spectate_example(game_id: game_id)

    GenServer.start(__MODULE__, game, name: get_name(game_id))
    update_liveview_list()

    {:ok, %{game_id: game_id, secret: secret, example: example, watch: watch}}
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

  def reset(game_id: game_id, secret: secret) do
    genserver_call(game_id, {:reset, secret})
  end

  def kick(game_id: game_id, secret: secret, handle: handle) do
    genserver_call(game_id, {:kick, secret, handle})
  end

  def expired?(game_id: game_id) do
    genserver_call(game_id, :expired?)
  end

  def update_liveview_list() do
    LiveHome.update_world_list(list_games())
  end

  def kill_expired_games() do
    list_games()
    |> Enum.filter(&expired?(game_id: &1))
    |> Enum.each(&kill(game_id: &1))

    :timer.apply_after(1000, __MODULE__, :update_liveview_list, [])
  end

  def kill(game_id: game_id) do
    name = get_name(game_id)

    with pid when is_pid(pid) <- GenServer.whereis(name),
         :ok <- GenServer.stop(name) do
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
    secret = SmallID.new()
    %Game{id: game_id} = new_game = Game.add_player(game, handle: handle, secret: secret)

    if Enum.count(new_game.players) > 9 do
      {:reply, {:error, "game is full"}, game}
    else
      example = move_example(game_id: game_id, secret: secret)
      watch = spectate_example(game_id: game_id)

      LiveGame.update_game(game: new_game)

      {:reply, {:ok, %{game_id: game_id, secret: secret, example: example, watch: watch}},
       new_game}
    end
  end

  @impl true
  def handle_call(:debug, _from, game) do
    {:reply, game, game}
  end

  @impl true
  def handle_call({:move, secret, move}, _from, %Game{} = game) do
    with {:ok, player} <- Game.fetch_player(game, secret),
         {:ok, world, player} <- World.next_world(game: game, player: player, move: move) do
      game =
        game
        |> Game.upsert_world(world)
        |> Game.upsert_player(secret, player)
        |> Game.upsert_clock()

      player_game = CreateWorlds.get_player_game(game, player)
      LiveGame.update_game(game: game)

      {:reply, {:ok, player_game}, game}
    else
      {:error, _msg} = err -> {:reply, err, game}
      err -> {:reply, err, game}
    end
  end

  @impl true
  def handle_call({:info, secret}, _from, %Game{} = game) do
    case Game.fetch_player(game, secret) do
      {:ok, player} ->
        player_game = CreateWorlds.get_player_game(game, player)
        game = Game.upsert_clock(game)
        {:reply, {:ok, player_game}, game}

      err ->
        {:reply, {:error, err}, game}
    end
  end

  @impl true
  def handle_call({:reset, secret}, _from, %Game{host_secret: secret} = game) do
    game =
      Game.reset_players(game)
      |> Game.upsert_clock()

    LiveGame.update_game(game: game)
    {:reply, {:ok, :ok}, game}
  end

  def handle_call({:reset, _secret}, _from, game) do
    {:reply, {:error, "unauthorized"}, game}
  end

  @impl true
  def handle_call(
        {:kick, secret, handle},
        _from,
        %Game{host_secret: secret, players: players} = game
      ) do
    if players[secret].handle == handle do
      {:reply, {:error, "cannot kick host"}, game}
    else
      game = Game.kick_player(game, handle: handle)
      LiveGame.update_game(game: game)
      {:reply, {:ok, :ok}, game}
    end
  end

  @impl true
  def handle_call({:kick, _secret, _handle}, _from, game) do
    {:reply, {:error, "unauthorized"}, game}
  end

  @impl true
  def handle_call(:expired?, _from, %Game{} = game) do
    {:reply, Game.is_expired(game), game}
  end
end
