defmodule EvolveWorld do
  # returns world tuple
  defp move(world, handle, {px, py}, {mx, my}) do
    x = px + mx
    y = py + my
    case Map.get(world, {x, y}) do
      nil -> {:ok, world}
      %{type: :wall} -> {:ok, world}  # you cannot move through walls
      %{type: empty} ->
        {:ok,
          Map.update!(world, {px, py}, fn square -> Map.delete(square, :player) end)
          |> Map.update!({x, y}, fn tile -> Map.put(tile, :player, handle) end)
        }
    end
  end

  # returns error tuple or square
  defp get_user(world, handle) do
    world
    |> Enum.to_list
    |> Enum.find(
      {:error, "player handle \"#{handle}\" not found"},
      fn {_, square} -> Map.get(square, :player) == handle end
    )
  end

  # returns direction or error
  # top left is origin
  defp parse_direction(direction) do
    case direction do
      "north" -> {:ok, {-1, 0}}
      "south" -> {:ok, {1, 0}}
      "east" -> {:ok, {0, 1}}
      "west" -> {:ok, {0, -1}}
      _ -> {:error, "invalid move"}
    end
  end

  defp world_for_client({:world, world}) do
    server_world = world
    client_world = world
    {:ok, server_world, client_world}
  end

  def next_world({:world, world}, %{player: handle, action: %{move: direction}}) do
    with {:ok, {mx, my}} <- parse_direction(direction),
         {position, %{player: handle}} <- get_user(world, handle),
         {:ok, world} <- move(world, handle, position, {mx, my}),
         {:ok, server_world, client_world} <- world_for_client({:world, world}) do
      {:ok, server_world, client_world}
    else
      {:error, msg} -> {:error, msg}
    end
  end
end
