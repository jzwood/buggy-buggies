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

    get "/host/:handle", GameController, :host
    get "/game/:game_id/join/:handle", GameController, :join
    get "/game/:game_id/player/:secret/info", GameController, :info
    get "/game/:game_id/player/:secret/move/:direction", GameController, :move
  end

  scope "/", LiveBuggiesWeb do
    pipe_through :browser

    live("/", LiveWorlds)
    live("/game/:game_id", LiveWorld)
  end

  # Other scopes may use custom stacks.
  # scope "/api", LiveBuggiesWeb do
  #   pipe_through :api
  # end
end
