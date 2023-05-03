defmodule CreateWorlds do
  @empty " "
  @wall "+"
  @water "~"
  @crate "#"
  @portal "@"
  @coin "$"
  @tree "^"

  def fst({a, _}), do: a
  def snd({_, b}), do: b

  defp is_raw_world_map?(file_name) do
    String.match?(file_name, ~r/^w\d+\.txt$/)
  end

  defp char_to_tile(char) when is_binary(char) do
    case char do
      @empty ->
        :empty

      @wall ->
        :wall

      @water ->
        :water

      @crate ->
        :crate

      @portal ->
        :portal

      @coin ->
        :coin

      @tree ->
        :tree

      c ->
        IO.inspect(c, label: "TILE")
        :error
    end
  end

  defp from_ascii(ascii_world) do
    Regex.split(~r/\n/, ascii_world)
    # |> Enum.reverse()
    |> Enum.map(fn row ->
      String.graphemes(row)
      |> Enum.map(&char_to_tile/1)
    end)
  end

  def get_player_game(%Game{} = game, %Player{} = player) do
    world =
      game.world
      |> Enum.filter(fn
        {_k, :empty} -> false
        _ -> true
      end)
      |> Map.new(fn {{x, y}, tile} -> {"#{x},#{y}", tile} end)

    players =
      Map.new(game.players, fn {_secret, %Player{handle: handle, x: x, y: y}} ->
        {handle, %{x: x, y: y}}
      end)

    %{world: world, dimensions: game.dimensions, players: players, you: player}
  end

  defp transform_world(world) do
    world
    |> Enum.with_index(fn row, y -> row |> Enum.with_index(fn tile, x -> {{x, y}, tile} end) end)
    |> Enum.concat()
    |> Enum.into(%{})
  end

  defp get_world_dimensions(world) do
    {mw, mh} =
      Enum.reduce(world, {0, 0}, fn {{x, y}, _val}, {mw, mh} -> {max(mw, x), max(mh, y)} end)

    %Dimensions{width: mw + 1, height: mh + 1}
  end

  def create_worlds() do
    working_dir = Path.dirname(__ENV__.file)
    target_dir = "raw_worlds"
    abs_path = Path.join(working_dir, target_dir)
    files = File.ls!(Path.join(working_dir, target_dir))

    files
    |> Enum.filter(&is_raw_world_map?/1)
    |> Enum.map(fn file ->
      path = Path.join(abs_path, file)
      contents = File.read!(path)
      world = create_world(contents)
      root = Path.rootname(file)
      dimensions = get_world_dimensions(world)
      {root, %{dimensions: dimensions, world: world}}
    end)
    |> Map.new()
  end

  defp create_world(ascii_world) do
    ascii_world
    |> String.trim()
    |> from_ascii()
    |> transform_world()
  end
end
