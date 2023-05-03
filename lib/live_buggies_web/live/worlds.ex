defmodule LiveBuggiesWeb.LiveWorlds do
  use Phoenix.LiveView
  use Phoenix.HTML
  alias LiveBuggiesWeb.GameComponent

  def mount(_session, _params, socket) do
    worlds = LiveBuggies.WorldServer.all()
    {:ok, assign(socket, :worlds, worlds)}
  end

  def render(assigns) do
    ~H"""
      <div class="cg0 columns-1 columns-2-l bg-gray">
        <%= for {name, %{dimensions: %{width: width, height: height}, world: world}} <- @worlds do %>
          <div class="map-container">
            <svg
              viewBox={"0 0 #{width} #{height}"}
              xmlns="http://www.w3.org/2000/svg"
              version="1.1"
              class="map"
            >
            <%= for {{x, y}, cell} <- world do %>
              <GameComponent.tile cell={cell} x={x} y={y} />
            <% end %>
            <text x="1" y="0.75" style="font-size: 0.5px; font-family: verdana;" class="ttl">
              <%= name %>
            </text>
            </svg>
          </div>
        <% end %>
      </div>
    """
  end
end
