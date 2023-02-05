defmodule LiveBuggiesWeb.LiveWorld do
  use Phoenix.LiveView

  @topic "live"

  def mount(session, params, socket) do
    # subscribe to the channel
    IO.inspect(session, label: "SESSION")
    Registry.register(:liveview_world_lookup, 123, nil)
    LiveBuggiesWeb.Endpoint.subscribe(@topic)
    {:ok, assign(socket, :val, 0)}
  end

  def handle_event("inc", _value, socket) do
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
    #IO.inspect("INC")
    GenServer.call(pid, "inc")
  end

  def handle_call(arg, pid, socket) do
    #IO.inspect(arg, label: "INC HANDLED")
    new_state = update(socket, :val, &(&1 - 1))
    IO.inspect({socket, new_state}, label: "HERE")
    LiveBuggiesWeb.Endpoint.broadcast_from(self(), @topic, "dec", new_state.assigns)
    {:reply, :cool, new_state}
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
