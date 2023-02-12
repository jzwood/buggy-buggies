defmodule LiveBuggiesWeb.LiveWorld do
  use Phoenix.LiveView
  use Phoenix.HTML
  alias LiveBuggiesWeb.GameComponent

  def mount(%{"game_id" => "random"} = session, params, socket) do
    with [game_id | _games] <- LiveBuggies.GameManager.list_games(),
         session <- Map.replace(session, "game_id", game_id),
         {:ok, socket} <- mount(session, params, socket) do
      {:ok, socket}
    else
      _ -> {:ok, assign(socket, :game, %Game{})}
    end
  end

  def mount(%{"game_id" => game_id} = _session, _params, socket) do
    Registry.register(:liveview_world_lookup, game_id, nil)
    game = LiveBuggies.GameManager.info(game_id: game_id)
    LiveBuggiesWeb.Endpoint.subscribe(game_id)
    {:ok, assign(socket, :game, game)}
  end

  def handle_info(msg, socket) do
    {:noreply, assign(socket, game: msg.payload.val)}
  end

  # def inc(pid, world_id) do
  # GenServer.cast(pid, world_id)
  # end

  def update_world(game_id: game_id, game: %Game{} = game) do
    LiveBuggiesWeb.Endpoint.broadcast_from(self(), game_id, "update_world", game: game)
  end

  defp get_world_dimensions(world) do
    {mw, mh} =
      Enum.reduce(world, {0, 0}, fn {{x, y}, _val}, {mw, mh} -> {max(mw, x), max(mh, y)} end)

    {mw + 1, mh + 1}
  end

  def render(assigns) do
    {mw, mh} = get_world_dimensions(assigns.game.world)

    ~H"""
    <div class="map-container">
      <svg
        viewBox={"0 0 #{mw} #{mh}"}
        xmlns="http://www.w3.org/2000/svg"
        version="1.1"
        class="map"
      >
        <GameComponent.background width={mw} height={mh} />
      <%= for {{x, y}, cell} <- @game.world do %>
        <GameComponent.tile cell={cell} x={x} y={y} />
      <% end %>
      <%= for player <- Map.values(@game.players) do %>
        <GameComponent.player x={player.x} y={player.y} history={player.history} />
      <% end %>
      </svg>
    </div>
    """
  end
end
