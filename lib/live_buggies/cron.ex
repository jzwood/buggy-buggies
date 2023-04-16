defmodule LiveBuggies.Cron do
  use GenServer

  alias LiveBuggies.GameManager

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    :timer.apply_interval(Game.expire_seconds() * 1000, GameManager, :kill_expired_games, [])
    {:ok, state}
  end
end
