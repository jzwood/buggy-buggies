defmodule LiveBuggiesWeb.Throttle do
  @moduledoc """
  throttles api calls
  """
  require Logger

  defp throttle?() do
    !Application.get_env(:live_buggies, :sandbox?)
  end

  def rate_limit(secret) do
    if throttle?() and rate_limit?(secret, 1, 10) do
      {:error, :throttle}
    else
      :ok
    end
  end

  def rate_limit?(key, window, max) do
    hits =
      case LiveBuggiesWeb.ThrottleCallCache.lookup(key) do
        [{_, value, _}] -> value
        _miss -> []
      end

    now = Rivet.Utils.Time.epoch_time()
    cutoff = now - window

    hits =
      [now | hits]
      |> Enum.filter(&(&1 > cutoff))

    true = LiveBuggiesWeb.ThrottleCallCache.insert(key, hits, window * 2)

    length(hits) > max
  end
end
