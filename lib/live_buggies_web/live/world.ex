defmodule LiveBuggiesWeb.LiveWorld do
  use Phoenix.LiveView

  @topic "888"

  def mount(%{"world_id" => world_id} = session, params, socket) do
    IO.inspect(session, label: "SESSION")
    Registry.register(:liveview_world_lookup, 123, nil)
    LiveBuggiesWeb.Endpoint.subscribe(@topic)
    {:ok, assign(socket, :val, 0)}
  end

  def handle_event("inc", value, socket) do
    IO.inspect(value, label: "HANDLE EVENT")
    new_state = update(socket, :val, &(&1 + 1))
    LiveBuggiesWeb.Endpoint.broadcast_from(self(), @topic, "inc", new_state.assigns)
    {:noreply, new_state}
  end

  def handle_event("dec", _, socket) do
    new_state = update(socket, :val, &(&1 - 1))
    LiveBuggiesWeb.Endpoint.broadcast_from(self(), @topic, "dec", new_state.assigns)
    {:noreply, new_state}
  end

  def handle_info(msg, socket) do
    {:noreply, assign(socket, val: msg.payload.val)}
  end

  def inc(pid) do
    GenServer.cast(pid, "inc")
  end

  def handle_call(arg, pid, socket) do
    new_state = update(socket, :val, &(&1 - 1))
    LiveBuggiesWeb.Endpoint.broadcast_from(self(), @topic, "dec", new_state.assigns)
    {:reply, :cool, new_state}
  end

  def handle_cast(arg, socket) do
    new_state = update(socket, :val, &(&1 - 1))
    LiveBuggiesWeb.Endpoint.broadcast_from(self(), @topic, "dec", new_state.assigns)
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
