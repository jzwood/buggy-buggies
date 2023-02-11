defmodule LiveBuggiesWeb.LiveWorlds do
  use Phoenix.LiveView

  @game_list "games"

  def mount(_session, _params, socket) do
    LiveBuggiesWeb.Endpoint.subscribe(@game_list)
    game_ids = LiveBuggies.GameManager.list_games()
    {:ok, assign(socket, :games, game_ids)}
  end

  def handle_info(msg, socket) do
    {:noreply, assign(socket, games: msg.payload)}
  end

  def update_world_list(game_ids) do
    # this broadcast gets picked up by handle_info
    LiveBuggiesWeb.Endpoint.broadcast_from(
      self(),
      @game_list,
      "update_game_list",
      game_ids
    )
  end

  def render(assigns) do
    ~L"""
    <div>
      <h1>Worlds</h1>
      <ul>
        <%= for game_id <- @games do %>
          <li>
            <a data-phx-link="redirect" data-phx-link-state="push" href="/game/<%= game_id %>">
              <%= game_id %>
            </a>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end
end
