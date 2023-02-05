defmodule LiveBuggiesWeb.CounterController do
  use LiveBuggiesWeb, :controller

  def incr(conn, _) do
    LiveBuggiesWeb.LiveWorld
    text(conn, "inc")
  end
end
