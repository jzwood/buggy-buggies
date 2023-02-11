defmodule LiveBuggiesWeb.LiveWorld do
  use Phoenix.LiveView
  use Phoenix.HTML

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

  #def inc(pid, world_id) do
    #GenServer.cast(pid, world_id)
  #end

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

    ~L"""
    <div class="map-container">
      <svg
        viewBox="0 0 <%= mw %> <%= mh %>"
        xmlns="http://www.w3.org/2000/svg"
        version="1.1"
        class="map"
      >
      <rect x="0" y="0" width="<%= mw %>" height="<%= mh %>" fill="gray" shape-rendering='optimizeSpeed' />
      <%= for {{x, y}, cell} <- @game.world do %>
        <% cx = x + 0.5 %>
        <% cy = y + 0.5 %>
        <%= if :wall == cell do %>
        <rect
          class="wall"
          x="<%= x %>"
          y="<%= y %>"
          width="1"
          height="1"
          fill="#CCC"
          shape-rendering="geometricPrecision"
        />
        <% end %>
        <%= if :water == cell do %>
        <rect
          class="water"
          x="<%= x %>"
          y="<%= y %>"
          width="1"
          height="1"
          fill="#005377"
          shape-rendering="geometricPrecision"
        />
        <% end %>
        <%= if :coin == cell do %>
        <circle
          class="coin"
          cx="<%= cx %>"
          cy="<%= cy %>"
          r="0.375"
          fill="#F1A208"
          shape-rendering="geometricPrecision"
        />
        <% end %>
        <%= if :crate == cell do %>
          <rect
            class="crate"
            x="<%= x %>"
            y="<%= y + 0.1 %>"
            width="1"
            height="0.8"
            fill="#644432"
            shape-rendering="geometricPrecision"
          />
        <% end %>
        <%= if :portal == cell do %>
          <ellipse
            class="portal"
            cx="<%= cx %>"
            cy="<%= cy %>"
            rx="0.4"
            ry="0.5"
            fill="#7D00C5"
          />
        <% end %>
        <%= if :trap == cell do %>
          <polygon
            class="trap"
            points="<%= x %>,<%= y + 1 %> <%= x + 0.5 %>,<%= y %> <%= x + 1 %>,<%= y + 1 %>"
          />
        <% end %>
      <% end %>
      <g class="buggy-n">
        <rect
          class="crate"
          x="13.25"
          y="11"
          width="0.5"
          height="1"
          fill="red"
          shape-rendering="geometricPrecision"
        />
        <rect
          class="crate"
          x="13.05"
          y="11.1"
          width="0.2"
          height="0.3"
          fill="black"
          shape-rendering="geometricPrecision"
        />
        <rect
          class="crate"
          x="13.75"
          y="11.1"
          width="0.2"
          height="0.3"
          fill="black"
          shape-rendering="geometricPrecision"
        />
        <rect
          class="crate"
          x="13.05"
          y="11.6"
          width="0.2"
          height="0.3"
          fill="black"
          shape-rendering="geometricPrecision"
        />
        <rect
          class="crate"
          x="13.75"
          y="11.6"
          width="0.2"
          height="0.3"
          fill="black"
          shape-rendering="geometricPrecision"
        />
      </g>
      </svg>
    </div>
    """
  end
end
