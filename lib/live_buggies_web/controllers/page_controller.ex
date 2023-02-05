defmodule LiveBuggiesWeb.PageController do
  use LiveBuggiesWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
