defmodule LiveBuggiesWeb.GameController do
  use LiveBuggiesWeb, :controller
  alias LiveBuggies.GameManager

  def host(conn, %{"handle" => handle}) do
    case GameManager.host(handle: handle) do
      {:ok, data} -> success(conn, data)
      _ -> failure(conn)
    end
  end

  def host(conn, _), do: failure(conn)

  def join(conn, %{"game_id" => game_id, "handle" => handle}) do
    case GameManager.join(game_id: game_id, handle: handle) do
      {:ok, secret} -> success(conn, secret)
      _ -> failure(conn)
    end
  end

  def join(conn, _), do: failure(conn)

  def move(conn, %{"game_id" => game_id, "secret" => secret, "direction" => direction}) do
    case GameManager.move(game_id: game_id, secret: secret, move: direction) do
      {:ok, game} -> success(conn, game)
      _ -> failure(conn)
    end
  end

  def move(conn, _) do
    failure(conn)
  end

  defp success(conn, result) do
    json(conn, %{success: true, reason: nil, result: result})
  end

  defp failure(conn, reason \\ "failed") do
    json(conn, %{success: false, reason: reason, result: nil})
  end
end