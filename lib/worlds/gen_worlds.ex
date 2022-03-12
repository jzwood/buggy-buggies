defmodule CreateWorlds do
  @empty " "
  @wall "+"
  @water "~"
  @crate "#"
  @portal "@"
  @coin "$"

  def fst {a,_} do
    a
  end

  def snd {_, b} do
    b
  end

  defp is_raw_world_map?(file_name) do
    String.match?(file_name, ~r/^w\d+\.txt$/)
  end

  defp char_to_tile(char) do
    case char do
      @empty -> %{type: :empty}
      @wall -> %{type: :wall}
      @water -> %{type: :water}
      @crate -> %{type: :crate}
      @portal -> %{type: :portal}
      @coin -> %{type: :coin}
      c -> cond do
        String.match?(c, ~r/^\d$/) -> %{type: :empty, player: c}
        true -> IO.inspect(char)
          :error
      end
    end
  end

  defp from_ascii(ascii_world) do
    Regex.split(~r/\n/, ascii_world)
    |> Enum.reverse
    |> Enum.map(&String.graphemes/1)
    |> Enum.reduce([], fn ascii_list, rows ->
      [
        ascii_list
        |> Enum.map(&char_to_tile/1)
        | rows
      ]
    end)
  end

  def to_ascii(world) do
    world
    |> Map.to_list
    |> Enum.group_by(fn {{x, _}, _} -> x end)  # maybe it's y?
    |> Enum.sort_by(&fst/1)
    |> Enum.map_join("\n", fn {n, row} ->
      row
      |> Enum.sort_by(fn {{_, y}, _} -> y end)
      |> Enum.map(&snd/1)
      |> Enum.map(&tile_to_ascii/1) end)
  end

  defp tile_to_ascii(%{player: handle}) do
    String.slice(handle, 0..0)
  end

  defp tile_to_ascii(%{type: type}) do
    case type do
      :empty -> @empty
      :wall -> @wall
      :water -> @water
      :crate -> @crate
      :portal -> @portal
      :coin -> @coin
      _ ->
        IO.inspect(type)
        :error
    end
  end

  defp transform_world(world) do
    world
    |> Enum.with_index(fn row, x -> row |> Enum.with_index(fn tile, y -> {{x, y}, tile} end) end)
    |> Enum.concat
    |> Enum.into(%{})
  end

  def get_ascii_worlds do
    working_dir = Path.dirname(__ENV__.file)
    target_dir = "raw_worlds"
    abs_path = Path.join(working_dir, target_dir)
    {ok, files} = File.ls(Path.join(working_dir, target_dir))
    files
    |> Enum.filter(&is_raw_world_map?/1)
    |> Enum.map(fn file -> Path.join(abs_path, file) end)
    |> Enum.map(&File.read/1)
    |> Enum.reduce([], fn ({:ok, content}, worlds) ->
      [
        content
        |> String.trim
        | worlds
      ]
    end)
  end

  def create_worlds ascii_worlds do
    ascii_worlds
    |> Enum.map(&from_ascii/1)
    |> Enum.map(&transform_world/1)
  end

  def create_world ascii_world do
    ascii_world
    |> from_ascii
    |> transform_world
  end
end
