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
    game = LiveBuggies.GameManager.info(game_id: game_id)
    LiveBuggiesWeb.Endpoint.subscribe(game_id)
    {:ok, assign(socket, :game, game)}
  end

  def handle_info(msg, socket) do
    # IO.inspect(msg.payload, label: "PAYLOAD")
    {:noreply, assign(socket, msg.payload)}
  end

  def update_game(game: %Game{id: game_id} = game) do
    LiveBuggiesWeb.Endpoint.broadcast_from(self(), game_id, "update_game", game: game)
  end

  defp get_world_dimensions(world) do
    {mw, mh} =
      Enum.reduce(world, {0, 0}, fn {{x, y}, _val}, {mw, mh} -> {max(mw, x), max(mh, y)} end)

    %{mw: mw + 1, mh: mh + 1}
  end

  defp orientation_of(%Player{history: []}), do: 0
  defp orientation_of(%Player{history: [_xy]}), do: 0
  defp orientation_of(%Player{history: [{x, _y1}, {x, _y2} | _history]}), do: 0
  defp orientation_of(_), do: 90

  defp avg({x1, y1}, {x2, y2}), do: {0.5 * (x1 + x2), 0.5 * (y1 + y2)}

  defp history_to_points([]), do: []
  defp history_to_points([_xy]), do: []

  defp history_to_points([p1, p2 | history]) do
    [avg(p1, p2), p2 | history]
    |> Enum.map_join(" ", fn {x, y} -> "#{x + 0.5},#{y + 0.5}" end)
  end

  def render(assigns) do
    assigns = assign(assigns, :dim, get_world_dimensions(assigns.game.world))

    ~H"""
    <div class="map-container">
      <svg
        viewBox={"0 0 #{@dim.mw} #{@dim.mh}"}
        xmlns="http://www.w3.org/2000/svg"
        version="1.1"
        class="map"
      >
      <rect x="0" y="0" width={@dim.mw} height={@dim.mh} fill="gray" shape-rendering='optimizeSpeed' />
      <%= for %{history: history} <- Map.values(@game.players) do %>
        <GameComponent.tire_tracks points={history_to_points(history)} />
      <% end %>
      <%= for {{x, y}, cell} <- @game.world do %>
        <GameComponent.tile cell={cell} x={x} y={y} />
      <% end %>
      <%= for player <- Map.values(@game.players) do %>
        <GameComponent.player x={player.x} y={player.y} orientation={orientation_of(player)} />
      <% end %>
      </svg>
    </div>
    """
  end
end
