defmodule LiveBuggiesWeb.GameController do
  use LiveBuggiesWeb, :controller
  alias LiveBuggies.GameManager

  # HOST
  def host(conn, %{"handle" => handle, "map" => map}) do
    case GameManager.host(handle: handle, map: map) do
      {:ok, data} -> success(conn, data)
      {:error, msg} -> failure(conn, msg)
      _ -> failure(conn)
    end
  end

  def host(conn, %{"handle" => handle}) do
    case GameManager.host(handle: handle) do
      {:ok, data} -> success(conn, data)
      {:error, msg} -> failure(conn, msg)
      _ -> failure(conn)
    end
  end

  def host(conn, _), do: failure(conn, "invalid host args")

  # JOIN
  def join(conn, %{"game_id" => game_id, "handle" => handle}) do
    case GameManager.join(game_id: game_id, handle: handle) do
      {:ok, data} -> success(conn, data)
      {:error, msg} -> failure(conn, msg)
      _ -> failure(conn)
    end
  end

  def join(conn, _), do: failure(conn, "invalid join args")

  # KICK
  def kick(conn, %{"game_id" => game_id, "secret" => secret, "handle" => handle}) do
    case GameManager.kick(game_id: game_id, secret: secret, handle: handle) do
      {:ok, game} -> success(conn, game)
      {:error, msg} -> failure(conn, msg)
      _ -> failure(conn)
    end
  end

  def kick(conn, _), do: failure(conn, "invalid kick args")

  # MOVE
  def move(conn, %{"game_id" => game_id, "secret" => secret, "direction" => direction}) do
    with :ok <- LiveBuggiesWeb.Throttle.rate_limit(secret),
         {:ok, game} <- GameManager.move(game_id: game_id, secret: secret, move: direction) do
      success(conn, game)
    else
      {:error, msg} -> failure(conn, msg)
      _ -> failure(conn)
    end
  end

  def move(conn, _), do: failure(conn, "invalid move args")

  # INFO
  def info(conn, %{"game_id" => game_id, "secret" => secret}) do
    with :ok <- LiveBuggiesWeb.Throttle.rate_limit(secret),
         {:ok, game} <- GameManager.info(game_id: game_id, secret: secret) do
      success(conn, game)
    else
      {:error, msg} -> failure(conn, msg)
      _ -> failure(conn)
    end
  end

  def info(conn, _), do: failure(conn, "invalid info args")

  # RESTART
  def reset(conn, %{"game_id" => game_id, "secret" => secret}) do
    with :ok <- LiveBuggiesWeb.Throttle.rate_limit(secret),
         {:ok, game} <- GameManager.reset(game_id: game_id, secret: secret) do
      success(conn, game)
    else
      {:error, msg} -> failure(conn, msg)
      _ -> failure(conn)
    end
  end

  def reset(conn, _), do: failure(conn, "invalid reset args")

  # KILL
  def kill(conn, %{"game_id" => game_id}) do
    case GameManager.kill(game_id: game_id) do
      :ok ->
        GameManager.update_liveview_list()
        success(conn, :ok)

      _ ->
        failure(conn)
    end
  end

  def kill(conn, _), do: failure(conn)

  defp success(conn, result) do
    json(conn, %{success: true, reason: nil, result: result})
  end

  defp failure(conn, reason \\ "something went wrong") do
    json(conn, %{success: false, reason: reason, result: nil})
  end
end
