defmodule LiveBuggiesWeb.LiveWorlds do
  use Phoenix.LiveView

  @world_list_topic "worlds"

  def mount(session, params, socket) do
    LiveBuggiesWeb.Endpoint.subscribe(@world_list_topic)
    world_ids = LiveBuggies.GameManager.list_worlds()
    {:ok, assign(socket, :worlds, world_ids)}
  end

  def handle_info(msg, socket) do
    {:noreply, assign(socket, worlds: msg.payload)}
  end

  def update_world_list(world_ids) do
    # this broadcast gets picked up by handle_info
    LiveBuggiesWeb.Endpoint.broadcast_from(self(), @world_list_topic, "update_world_list", world_ids)
  end

  def render(assigns) do
    ~L"""
    <div>
      <h1>Worlds</h1>
      <ul>
        <%= for world_id <- @worlds do %>
          <li>
            <a data-phx-link="redirect" data-phx-link-state="push" href="/world/<%= world_id %>">
              <%= world_id %>
            </a>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end
end
