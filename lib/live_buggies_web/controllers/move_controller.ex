defmodule LiveBuggiesWeb.GameController do
  use LiveBuggiesWeb, :controller
  alias LiveBuggies.GameManager

  def move(conn, %{"game_id" => game_id, "secret" => secret, "direction" => direction}) do
    case GameManager.move(game_id: game_id, secret: secret, move: direction) do
      {:ok, _world, _player} -> success(conn, "result")
      _ -> failure(conn, "failed")
    end
  end

  def move(conn, _) do
    failure(conn, "bad input")
  end

  def host(conn, %{"handle" => handle}) do
    case GameManager.host(handle: handle) do
      {:ok, data} -> success(conn, data)
      _ -> failure(conn, "failed")
    end
  end

  defp success(conn, result) do
    json(conn, %{success: true, reason: nil, result: result})
  end

  defp failure(conn, reason) do
    json(conn, %{success: false, reason: reason, result: nil})
  end
end
