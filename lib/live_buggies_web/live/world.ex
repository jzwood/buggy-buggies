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

  def render(assigns) do
    IO.inspect(assigns, label: "ASSIGN")
    ~L"""
    <div>
      <h1>The count is: <%= @game.host_secret %></h1>
    </div>
    """
  end
end
