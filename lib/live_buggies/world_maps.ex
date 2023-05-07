defmodule LiveBuggies.WorldMaps do
  @moduledoc """
  datastructures for all world maps
  """
  @worlds CreateWorlds.create_worlds()

  def get(root) do
    Map.get(@worlds, root)
  end

  def all() do
    @worlds
  end

  def random() do
    rand_key =
      @worlds
      |> Map.keys()
      |> Enum.random()

    rand_world = Map.get(@worlds, rand_key)
    {rand_key, rand_world}
  end

  def exists?(name) do
    Map.has_key?(@worlds, name)
  end
end
