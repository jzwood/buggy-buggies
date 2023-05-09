defmodule CreateWorlds do
  @moduledoc """
  transforms raw text versions of world maps into elixir datastructures
  """
  require Logger

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
    String.match?(file_name, ~r/^\w+\.txt$/)
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
        Logger.info("unexpected tile #{c}")
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

  def get_player_game(%Game{players: players} = game, %Player{handle: handle} = player) do
    world =
      game.world
      |> Enum.filter(fn
        {_k, :empty} -> false
        _ -> true
      end)
      |> Map.new(fn {{x, y}, tile} -> {"#{x},#{y}", tile} end)

    players =
      players
      |> Enum.filter(fn
        {_secret, %Player{handle: ^handle}} -> false
        {_secret, _} -> true
      end)
      |> Enum.map(fn {_secret, %Player{handle: handle, x: x, y: y}} -> {handle, %{x: x, y: y}} end)
      |> Map.new()

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
