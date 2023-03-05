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
    ~H"""
    <div class="flex flex-column min-vh-100">
      <main class="flex-grow-1 ph3 ph2">
        <div class="flex items-baseline gh3 flex-wrap">
          <h2>buggy buggies</h2>
          <p>
            a game where the only way to win is by writing the best AI for a virtual dune-buggy.
          </p>
        </div>
        <div class="flex gh4 items-baseline">
          <h2>host</h2>
          <pre class="break-spaces">GET /api/host/&lt;handle&gt;</pre>
        </div>
        <div class="flex gh4 items-baseline">
          <h2>friends join</h2>
          <pre class="break-spaces">/game/&lt;game_id&gt;/join/&lt;handle&gt;</pre>
        </div>
        <div class="flex gh4 items-baseline">
          <h2>start game</h2>
          <pre class="break-spaces">/game/&lt;game_id&gt;/player/&lt;secret&gt;/start</pre>
        </div>
        <div class="flex gh3 items-baseline flex-wrap">
          <h2>game loop</h2>
          <p>collect gold. avoid crashing.</p>
        </div>
        <div class="flex gh4 items-baseline">
          <h2>move<sup>†</sup></h2>
          <pre class="break-spaces">GET /api/game/&lt;game_id&gt;/player/&lt;secret&gt;/move/&lt;N|E|S|W&gt;</pre>
        </div>
        <div class="flex gh4 items-baseline">
          <h2>win</h2>
          <p>first buggy to collect 20 gold wins.</p>
        </div>
        <h2>games</h2>
        <ol>
          <%= for game_id <- @games do %>
            <li>
              <a data-phx-link="redirect" data-phx-link-state="push" href={"/game/#{ game_id }"}>
                <%= game_id %>
              </a>
            </li>
          <% end %>
        </ol>
      </main>
      <footer class="pv1 ph3 bg-moon-gray">
        <div class="flex gh2 items-baseline">
          <h3>†</h3>
          <i>api rate limit: 3 requests / second</i>
        </div>
      </footer>
    </div>
    """
  end
end
