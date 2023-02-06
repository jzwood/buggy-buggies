defmodule LiveBuggiesWeb.LiveWorld do
  use Phoenix.LiveView

  @topic "888"

  def mount(%{"world_id" => world_topic} = session, params, socket) do
    IO.inspect(session, label: "SESSION")
    Registry.register(:liveview_world_lookup, world_topic, nil)
    LiveBuggiesWeb.Endpoint.subscribe(world_topic)
    {:ok, assign(socket, :val, 0)}
  end

  def handle_info(msg, socket) do
    {:noreply, assign(socket, val: msg.payload.val)}
  end

  def inc(pid, world_id) do
    GenServer.cast(pid, world_id)
  end

  def handle_cast(world_id, socket) do
    IO.inspect(world_id, label: "ARG")
    new_state = update(socket, :val, &(&1 - 1))
    LiveBuggiesWeb.Endpoint.broadcast_from(self(), world_id, "dec", new_state.assigns)
    {:noreply, new_state}
  end

  def render(assigns) do
    ~L"""
    <div>
      <h1>The count is: <%= @val %></h1>
      <button phx-click="dec">-</button>
      <button phx-click="inc">+</button>
    </div>
    """
  end
end
