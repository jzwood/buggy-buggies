defmodule LiveBuggiesWeb.LiveWorld do
  use Phoenix.LiveView
  use Phoenix.HTML

  def mount(%{"world_id" => world_id} = _session, _params, socket) do
    Registry.register(:liveview_world_lookup, world_id, nil)
    game = LiveBuggies.GameManager.info(game_id: world_id)
    LiveBuggiesWeb.Endpoint.subscribe(world_id)
    {:ok, assign(socket, :game, game)}
  end

  def handle_info(msg, socket) do
    {:noreply, assign(socket, game: msg.payload.val)}
  end

  def inc(pid, world_id) do
    GenServer.cast(pid, world_id)
  end

  def update_world(world_id: world_id, game: %Game{} = game) do
    LiveBuggiesWeb.Endpoint.broadcast_from(self(), world_id, "update_world", game: game)
  end

  defp get_world_dimensions(world) do
    {mw, mh} = Enum.reduce(world, {0, 0}, fn {{x, y}, _val}, {mw, mh} -> {max(mw, x), max(mh, y)} end)
    {mw + 1, mh + 1}
  end

  defp tile_to_svg(tile, x, y) do
    case tile do
      :empty -> ""
      :wall ->  "<rect x='#{x}' y='#{y}' width='1' height='1' fill='#CCC' shape-rendering='geometricPrecision' />"
      :water -> "<rect x='#{x}' y='#{y}' width='1' height='1' fill='#005377' shape-rendering='geometricPrecision' />"
      :crate ->  ""
      :portal ->  ""
      :coin -> "<circle cx='#{x}' cy='#{y}' r='0.5' fill='#f1a208' shape-rendering='geometricPrecision' />"
      :trap ->  ""
      :spawn ->  ""
    end
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
        <%= raw tile_to_svg(cell, x, y) %>
      <% end %>
      </svg>
    </div>
    """
  end
end
