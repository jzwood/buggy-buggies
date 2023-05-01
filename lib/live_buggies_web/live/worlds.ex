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
      <main class="worlds mw8 center items-baseline gv3 gh4 ph3 pv2 pv4-m pv5-l">
        <h2>buggy buggies</h2>
        <p>
          a game where winning means writing the best dune-buggy AI.
        </p>
        <h2>host</h2>
        <pre class="break-spaces break-word">GET /api/host/&lt;handle&gt;</pre>
        <h2>friends join</h2>
        <pre class="break-spaces break-word">GET /api/game/&lt;game_id&gt;/join/&lt;handle&gt;</pre>
        <h2>move<sup class="courier normal">†</sup></h2>
        <pre class="break-spaces break-word">GET /api/game/&lt;game_id&gt;/player/&lt;secret&gt;/move/&lt;N|E|S|W&gt;</pre>
        <h2>game state?</h2>
        <pre class="break-spaces break-word">GET /api/game/&lt;game_id&gt;/player/&lt;secret&gt;/info</pre>
        <h2>win</h2>
        <div>
          <p><strike>beautiful algorithms are their own reward.</strike></p>
          <p>collect gold. avoid crashing. most gold wins.</p>
        </div>
        <h2>beep boop</h2>
        <a href="https://github.com/jzwood/buggy-buggies/tree/main/examples" target="_blank">code samples</a>
        <h2>spectate</h2>
        <%= if length(@games) == 0 do %>
          <i>no games in progress</i>
        <% end %>
        <ol>
          <%= for game_id <- @games do %>
            <li>
              <a data-phx-link="redirect" data-phx-link-state="push" href={"/game/#{ game_id }"}><%= game_id %></a>
            </li>
          <% end %>
        </ol>
      </main>
      <div class="flex-grow-1"></div>
      <footer class="flex items-center justify-between gh2 mt2 pv1 ph3 bg-moon-gray">
        <div class="flex gh2 items-baseline">
          <h3 class="courier normal">†</h3>
          <i>api rate limit: 10 requests / second</i>
        </div>
        <a href="https://github.com/jzwood/buggy-buggies" target="_blank" class="flex flex-shrink-0">
          <img class="h2 mv1" src="/images/github-mark.svg" alt="view project on github"/>
        </a>
      </footer>
    </div>
    """
  end
end
