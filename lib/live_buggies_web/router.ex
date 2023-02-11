defmodule LiveBuggiesWeb.Router do
  use LiveBuggiesWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {LiveBuggiesWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", LiveBuggiesWeb do
    pipe_through :api

    get "/inc/:world", CounterController, :incr
    # get "/:id/move/:direction", MoveController, :move
  end

  scope "/", LiveBuggiesWeb do
    pipe_through :browser

    live("/", LiveWorlds)
    live("/world/:world_id", LiveWorld)
  end

  # Other scopes may use custom stacks.
  # scope "/api", LiveBuggiesWeb do
  #   pipe_through :api
  # end
end
