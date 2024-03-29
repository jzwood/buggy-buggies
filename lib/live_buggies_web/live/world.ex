defmodule LiveBuggiesWeb.LiveGame do
  @moduledoc """
  liveview representation of a specific game
  """

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
    case LiveBuggies.GameManager.debug(game_id: game_id) do
      %Game{} = game ->
        LiveBuggiesWeb.Endpoint.subscribe(game_id)
        {:ok, assign(socket, :game, game)}

      _ ->
        {:ok, assign(socket, :game, %Game{})}
    end
  end

  def handle_info(msg, socket) do
    {:noreply, assign(socket, msg.payload)}
  end

  def update_game(game: %Game{id: game_id} = game) do
    LiveBuggiesWeb.Endpoint.broadcast_from(self(), game_id, "update_game", game: game)
  end

  defp orientation_of(%Player{history: []}), do: 0
  defp orientation_of(%Player{history: [_xy]}), do: 0
  defp orientation_of(%Player{history: [{x, _y1}, {x, _y2} | _history]}), do: 0
  defp orientation_of(_), do: 90

  # defp avg({x1, y1}, {x2, y2}), do: {0.5 * (x1 + x2), 0.5 * (y1 + y2)}
  defp manhattan_distance({x1, y1}, {x2, y2}), do: abs(x2 - x1) + abs(y2 - y1)

  defp history_to_points([]), do: []
  defp history_to_points([_xy]), do: []

  defp history_to_points(history) do
    history
    |> Enum.map(fn {x, y} -> {x + 0.5, y + 0.5} end)
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.filter(fn [p1, p2] -> manhattan_distance(p1, p2) == 1 end)
  end

  def render(assigns) do
    ~H"""
    <div class="map-container">
      <svg
        viewBox={"0 0 #{@game.dimensions.width} #{@game.dimensions.height}"}
        xmlns="http://www.w3.org/2000/svg"
        version="1.1"
        class="map"
      >
      <rect x="0" y="0" width={@game.dimensions.width} height={@game.dimensions.height} fill="gray" shape-rendering="optimizeSpeed" />
      <%= for %{history: history} <- Map.values(@game.players) do %>
        <%= for [{x1, y1}, {x2, y2}] <- history_to_points(history) do %>
          <GameComponent.tire_tracks x1={x1} y1={y1} x2={x2} y2={y2} />
        <% end %>
      <% end %>
      <%= for {{x, y}, cell} <- @game.world do %>
        <GameComponent.tile cell={cell} x={x} y={y} />
      <% end %>
      <%= for player <- Map.values(@game.players) do %>
        <GameComponent.player x={player.x} y={player.y} boom={player.boom} index={player.index} orientation={orientation_of(player)} />
      <% end %>
      <text x="1" y="0.75" style="font-size: 0.5px; font-family: verdana;" class="ttl">
        <%= Map.values(@game.players) |> Enum.map_join(" | ", fn %{handle: handle, boom: boom, purse: purse} -> "#{handle}: #{purse} #{if boom, do: "x", else: ""}" end) %>
      </text>
      </svg>
    </div>
    """
  end
end
