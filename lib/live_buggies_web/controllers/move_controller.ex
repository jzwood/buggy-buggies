defmodule LiveBuggiesWeb.MoveController do
  use LiveBuggiesWeb, :controller

  def move(conn, %{"game_id" => game_id, "secret" => secret, "direction" => direction}) do
    json(conn, %{"success" => true, "cat" => "man"})
  end

  def move(conn, _) do
    json(conn, %{"success" => false})
  end
end

