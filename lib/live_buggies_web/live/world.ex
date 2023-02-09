defmodule LiveBuggiesWeb.LiveWorld do
  use Phoenix.LiveView

  def mount(%{"world_id" => world_id} = session, params, socket) do
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

  #def handle_cast(world_id, socket) do
    #new_state = update(socket, :val, &(&1 - 1))
    #LiveBuggiesWeb.Endpoint.broadcast_from(self(), world_id, "dec", new_state.assigns)
    #{:noreply, new_state}
  #end

  defp get_world_dimensions(world) do
    Enum.reduce(world, {0, 0}, fn {{x, y}, val}, {mw, mh} -> {max(mw, x), max(mh, y)} end)
  end

  defp tile_to_img(tile) do
    case tile do
      :empty -> "/images/empty.png"
      :wall ->  "/images/wall.png"
      :water ->  "/images/water.png"
      :crate ->  "/images/crate.png"
      :portal ->  ""
      :coin ->  "/images/gold.png"
      :trap ->  ""
      :spawn ->  ""
    end
  end

  def render(assigns) do
    {mw, mh} = get_world_dimensions(assigns.game.world)
    #IO.inspect(assigns, label: "ASSIGN")
    ~L"""
    <div class="map-container">
      <svg
        viewBox="0 0 <%= mw + 1 %> <%= mh + 1 %>"
        xmlns="http://www.w3.org/2000/svg"
        version="1.1"
        class="map"
      >
      <%= for {{x, y}, cell} <- @game.world do %>
        <image href="<%= tile_to_img(cell) %>" x="<%= x %>" y="<%= y %>" height="1" width="1"/>
      <% end %>
      </svg>
    </div>
    """
  end
end
