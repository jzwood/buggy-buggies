defmodule Player do
  @moduledoc false
  @derive {Jason.Encoder, only: [:handle, :purse, :boom, :x, :y]}
  defstruct handle: nil,
            index: 0,
            purse: 0,
            boom: false,
            x: nil,
            y: nil,
            history: []
end

defmodule Dimensions do
  @moduledoc false
  @derive Jason.Encoder
  defstruct width: 0, height: 0
end

defmodule Game do
  @moduledoc false
  @expire_seconds 60 * 60

  defstruct id: nil,
            world: %{},
            dimensions: %Dimensions{},
            host_secret: "",
            players: %{},
            updated_at: 0

  def expire_seconds(), do: @expire_seconds

  def now(), do: :os.system_time(:second)

  def is_expired(%Game{updated_at: updated_at}) do
    updated_at + @expire_seconds < now()
  end

  def fetch_player(game, player_secret) do
    Map.fetch(game.players, player_secret)
  end

  def add_player(%Game{} = game, handle: handle, secret: secret) do
    {x, y} = World.random_empty(game)
    index = Enum.count(game.players)

    Game.upsert_player(game, secret, %Player{
      handle: handle,
      x: x,
      y: y,
      index: index,
      history: [{x, y}]
    })
  end

  def kick_player(%Game{players: players} = game, handle: handle) do
    players =
      players
      |> Enum.filter(fn {_secret, %Player{} = player} -> player.handle != handle end)
      |> Map.new()

    %Game{game | players: players}
  end

  def reset_player!(%Game{} = game, secret: secret) do
    {:ok, player} = fetch_player(game, secret)
    {x, y} = World.random_empty(game)

    upsert_player(game, secret, %Player{
      player
      | purse: 0,
        boom: false,
        x: x,
        y: y,
        history: [{x, y}]
    })
  end

  def reset_players(%Game{} = game) do
    secrets = Map.keys(game.players)
    Enum.reduce(secrets, game, fn secret, game -> Game.reset_player!(game, secret: secret) end)
  end

  def get_player_positions(%Game{} = game) do
    Map.values(game.players)
    |> Enum.map(fn %Player{x: x, y: y} -> {x, y} end)
    |> MapSet.new()
  end

  def upsert_player(%Game{} = game, secret, player) do
    %Game{game | players: Map.put(game.players, secret, player)}
  end

  def upsert_world(%Game{} = game, world) do
    %Game{game | world: world}
  end

  def upsert_clock(%Game{} = game) do
    %Game{game | updated_at: now()}
  end
end

defmodule World do
  @moduledoc false
  @history_limit 45

  defp update_history([], {x, y}), do: [{x, y}]
  defp update_history([{x, y} | _history] = history, {x, y}), do: history
  defp update_history(history, {x, y}), do: [{x, y} | history] |> Enum.take(@history_limit)

  defp update_position(%Player{history: history} = player, {x, y}) do
    %Player{player | x: x, y: y, history: update_history(history, {x, y})}
  end

  defp increment_purse(%Player{purse: purse} = player), do: %Player{player | purse: purse + 1}
  defp crash(%Player{boom: _boom} = player), do: %Player{player | boom: true}

  defp collision?(player: %Player{x: px, y: py}, move: {mx, my}, players: players) do
    px = px + mx
    py = py + my

    case players
         |> Map.values()
         |> Enum.find(fn %Player{x: x, y: y} -> x == px and y == py end)
         |> is_nil() do
      true -> :ok
      false -> {:error, "square already occupied"}
    end
  end

  defp move(game, %Player{boom: true} = player, _m), do: {:ok, game.world, player}

  defp move(%Game{world: world} = game, %Player{x: px, y: py} = player, {mx, my}) do
    x = px + mx
    y = py + my

    case Map.get(world, {x, y}) do
      nil ->
        {:error, "cannot leave map"}

      :empty ->
        {:ok, world, update_position(player, {x, y})}

      :coin ->
        world =
          world
          |> Map.replace(World.random_empty(game), :coin)
          |> Map.replace({x, y}, :empty)

        player =
          player
          |> update_position({x, y})
          |> increment_purse()

        # maybe payouts are randomly 1, 2, or 3
        {:ok, world, player}

      :portal ->
        position = random_portal(world, {x, y})

        player =
          player
          |> update_position({x, y})
          |> update_position(position)

        {:ok, world, player}

      :wall ->
        {:error, "cannot move through walls"}

      :water ->
        player =
          player
          |> update_position({x, y})
          |> crash()

        {:ok, world, player}

      :tree ->
        player =
          player
          |> update_position({x, y})
          |> crash()

        {:ok, world, player}

      :crate ->
        # eh, nothing with crates yet
        {:ok, world, update_position(player, {x, y})}
    end
  end

  defp parse_direction(direction) do
    case String.upcase(direction) do
      "W" -> {:ok, {-1, 0}}
      "E" -> {:ok, {1, 0}}
      "S" -> {:ok, {0, 1}}
      "N" -> {:ok, {0, -1}}
      _ -> {:error, "unknown direction"}
    end
  end

  def random_empty(%Game{world: world} = game) do
    player_positions = Game.get_player_positions(game)

    world
    |> Map.filter(fn
      {xy, :empty} -> not MapSet.member?(player_positions, xy)
      {_k, _v} -> false
    end)
    |> Map.keys()
    |> Enum.random()
  end

  def random_portal(world, {_x, _y} = k) do
    world
    |> Map.filter(fn
      {^k, :portal} -> false
      {_k, :portal} -> true
      {_k, _v} -> false
    end)
    |> Map.keys()
    |> Enum.random()
  end

  def next_world(game: %Game{players: players} = game, player: player, move: direction) do
    with {:ok, {mx, my}} <- parse_direction(direction),
         :ok <- collision?(player: player, move: {mx, my}, players: players) do
      move(game, player, {mx, my})
    end
  end
end
