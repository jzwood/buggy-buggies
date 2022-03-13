defmodule BuggyBuggiesTest do
  use ExUnit.Case
  require EvolveWorld
  require CreateWorlds
  require BuggyWorld

  doctest BuggyWorld

  def clean_ascii_world ascii_world do
    Regex.replace(~r/ +?\+./, ascii_world, "+")
  end

  def chain_next_world {:ok, world, _} do
    {:world, world}
  end

  setup do
    handle = "racoon"
    world = %{
      {0, 0} => %{type: :wall},
      {0, 1} => %{type: :wall},
      {0, 2} => %{type: :wall},
      {0, 3} => %{type: :wall},
      {0, 4} => %{type: :wall},
      {1, 0} => %{type: :wall},
      {1, 1} => %{type: :water},
      {1, 2} => %{type: :empty},
      {1, 3} => %{type: :empty},
      {1, 4} => %{type: :wall},
      {2, 0} => %{type: :wall},
      {2, 1} => %{type: :empty},
      {2, 2} => %{type: :water},
      {2, 3} => %{type: :empty},
      {2, 4} => %{type: :wall, player: handle},
      {3, 0} => %{type: :wall},
      {3, 1} => %{type: :wall},
      {3, 2} => %{type: :wall},
      {3, 3} => %{type: :wall},
      {3, 4} => %{type: :wall}
    }
    %{world: world, player: handle}
  end

  #test "move", %{world: world, player: handle} do
    #direction = "south"
    #action = %{player: handle, action: %{move: direction}}
    #{:world, next_world} = EvolveWorld.next_world({:world, world}, action)
    #assert Map.get(next_world, {2, 3}) == %{player: "racoon", type: :empty}
  #end

  test "ascii to world to ascii" do
    ascii_world = ~S"""
      +++++++
      +  @  +
      +  $  +
      +     +
      +~  # +
      +  ~# +
      +++++++
    """
    world = CreateWorlds.create_world(ascii_world)
    ascii_world_new = CreateWorlds.to_ascii(world)
    assert String.trim(ascii_world) == String.trim(ascii_world_new)
  end

  test "basic move vertical (lib)" do
    init_ascii_world = ~S"""
      +++++
      + 1#+
      +   +
      +~ $+
      +++++
    """
    expected_ascii_world = ~S"""
      +++++
      +  #+
      +   +
      +~1$+
      +++++
    """
    world = CreateWorlds.create_world(init_ascii_world)
    {:world, new_world} = EvolveWorld.next_world({:world, world}, %{player: "1", action: %{move: "south"}})
                          |> chain_next_world
                          |> EvolveWorld.next_world(%{player: "1", action: %{move: "south"}})
                          |> chain_next_world

    new_ascii_world = CreateWorlds.to_ascii(new_world)
    assert String.trim(new_ascii_world) == String.trim(expected_ascii_world)
  end

  test "basic move horizontal" do
    init_ascii_world = ~S"""
      +++++
      +  #+
      +1  +
      +~$ +
      +++++
    """
    expected_ascii_world = ~S"""
      +++++
      +  #+
      +  1+
      +~$ +
      +++++
    """
    world = CreateWorlds.create_world(init_ascii_world)
    {:world, new_world} = EvolveWorld.next_world({:world, world}, %{player: "1", action: %{move: "east"}})
                          |> chain_next_world
                          |> EvolveWorld.next_world(%{player: "1", action: %{move: "east"}})
                          |> chain_next_world

    new_ascii_world = CreateWorlds.to_ascii(new_world)
    assert String.trim(new_ascii_world) == String.trim(expected_ascii_world)
  end

  test "basic move diagonal" do
    init_ascii_world = ~S"""
      +++++
      +   +
      +   +
      +  1+
      +++++
    """
    expected_ascii_world = ~S"""
      +++++
      +   +
      +1  +
      +   +
      +++++
    """
    world = CreateWorlds.create_world(init_ascii_world)
    {:world, new_world} = EvolveWorld.next_world({:world, world}, %{player: "1", action: %{move: "north"}})
                          |> chain_next_world
                          |> EvolveWorld.next_world(%{player: "1", action: %{move: "west"}})
                          |> chain_next_world
                          |> EvolveWorld.next_world(%{player: "1", action: %{move: "west"}})
                          |> chain_next_world

    new_ascii_world = CreateWorlds.to_ascii(new_world)
    assert String.trim(new_ascii_world) == String.trim(expected_ascii_world)
  end

  test "cannot move through walls" do
    init_ascii_world = ~S"""
      +++
      +1+
      +++
    """
    expected_ascii_world = init_ascii_world
    world = CreateWorlds.create_world(init_ascii_world)
    {:world, world} = EvolveWorld.next_world({:world, world}, %{player: "1", action: %{move: "north"}})
                      |> chain_next_world
    assert String.trim(init_ascii_world) == String.trim(CreateWorlds.to_ascii(world))
    {:world, world} = EvolveWorld.next_world({:world, world}, %{player: "1", action: %{move: "east"}})
                      |> chain_next_world
    assert String.trim(init_ascii_world) == String.trim(CreateWorlds.to_ascii(world))
    {:world, world} = EvolveWorld.next_world({:world, world}, %{player: "1", action: %{move: "south"}})
                      |> chain_next_world
    assert String.trim(init_ascii_world) == String.trim(CreateWorlds.to_ascii(world))
    {:world, world} = EvolveWorld.next_world({:world, world}, %{player: "1", action: %{move: "west"}})
                      |> chain_next_world
    assert String.trim(init_ascii_world) == String.trim(CreateWorlds.to_ascii(world))
  end

  test "cannot move through water" do
  end

  test "collects coins" do
  end

  test "collects crate" do
  end

  test "portal teleports" do
  end

  test "basic move (api)" do
    init_ascii_world = ~S"""
      +++++
      + 1#+
      +   +
      +~ $+
      +++++
    """
    expected_ascii_world = ~S"""
      +++++
      +  #+
      +   +
      +~1$+
      +++++
    """
    world = CreateWorlds.create_world(init_ascii_world)
    {:ok, pid} = BuggyWorld.start_link(world)
    assert world == BuggyWorld.get_world(pid)
    {:ok, world} = BuggyWorld.take_turn(pid, "1", "south")
    assert world == BuggyWorld.get_world(pid)
    {:ok, world} = BuggyWorld.take_turn(pid, "1", "south")
    assert world == BuggyWorld.get_world(pid)

    ascii_world = CreateWorlds.to_ascii(world)
    assert String.trim(ascii_world) == String.trim(expected_ascii_world)
  end

end
