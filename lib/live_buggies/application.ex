defmodule LiveBuggies.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      LiveBuggiesWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: LiveBuggies.PubSub},
      BuggyBuggies.GameManager,
      {Registry, keys: :unique, name: :liveview_world_lookup},

      # Start the Endpoint (http/https)
      LiveBuggiesWeb.Endpoint
      # Start a worker by calling: LiveBuggies.Worker.start_link(arg)
      # {LiveBuggies.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LiveBuggies.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LiveBuggiesWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
