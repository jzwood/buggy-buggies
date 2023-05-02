defmodule LiveBuggiesWeb.LiveWorlds do
  use Phoenix.LiveView
  use Phoenix.HTML
  alias LiveBuggiesWeb.GameComponent

  def mount(_session, _params, socket) do
    worlds = LiveBuggies.WorldServer.all()
    {:ok, assign(socket, :worlds, worlds)}
  end

  # ADD WIDTH AND HEIGHT TO WORLD DATA
  def render(assigns) do
    #assigns = assign(assigns, :dim, get_world_dimensions(assigns.game.world))

    ~H"""
    <div class="map-container">
      <svg
        viewBox={"0 0 #{@dim.mw} #{@dim.mh}"}
        xmlns="http://www.w3.org/2000/svg"
        version="1.1"
        class="map"
      >
      <rect x="0" y="0" width={@dim.mw} height={@dim.mh} fill="gray" shape-rendering="optimizeSpeed" />
      <%= for {{x, y}, cell} <- @game.world do %>
        <GameComponent.tile cell={cell} x={x} y={y} />
      <% end %>
      </svg>
    </div>
    """
  end
end
