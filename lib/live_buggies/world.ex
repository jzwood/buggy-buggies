defmodule Player do
  @derive {Jason.Encoder, only: [:handle, :purse, :booms, :x, :y]}
  defstruct handle: nil,
            purse: 0,
            booms: 0,
            x: nil,
            y: nil,
            history: []
end

defmodule Game do
  defstruct id: nil, world: %{}, host_secret: "", players: %{}, open: false

  def fetch_player(game, player_secret) do
    Map.fetch(game.players, player_secret)
  end

  def add_player(%Game{} = game, handle: handle, secret: secret) do
    {x, y} = World.random_spawn(game.world)
    Game.upsert_player(game, secret, %Player{handle: handle, x: x, y: y})
  end

  def upsert_player(%Game{} = game, secret, player) do
    %Game{game | players: Map.put(game.players, secret, player)}
  end

  def upsert_world(%Game{} = game, world) do
    %Game{game | world: world}
  end

  def start(%Game{host_secret: host_secret, open: false} = game, host_secret) do
    {:ok, %{game | open: true}}
  end

  def start(_), do: :error
end

defmodule World do
  defp move(world, %Player{purse: purse, x: px, y: py} = player, {mx, my}) do
    x = px + mx
    y = py + my

    case Map.get(world, {x, y}) do
      nil ->
        {:error, "cannot leave map"}

      :empty ->
        {:ok, world, %Player{player | x: x, y: y}}

      :spawn ->
        {:ok, world, %Player{player | x: x, y: y}}

      :crate ->
        # eh, nothing with crates yet
        {:ok, world, %Player{player | x: x, y: y}}

      :coin ->
        world = Map.replace(world, {x, y}, :empty)
        player = %Player{player | x: x, y: y, purse: purse + 1}
        # maybe payouts are randomly 1, 2, or 3
        {:ok, world, player}

      :wall ->
        {:error, "cannot move through walls"}

      :water ->
        {:error, "cannot cross water"}
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

  def random_spawn(world) do
    world
    |> Map.filter(fn
      {_k, :spawn} -> true
      {_k, _v} -> false
    end)
    |> Map.keys()
    |> Enum.random()
  end

  def next_world(world: world, player: player, move: direction) do
    with {:ok, {mx, my}} <- parse_direction(direction),
         {:ok, world, player} <- move(world, player, {mx, my}) do
      {:ok, world, player}
    end
  end
end
