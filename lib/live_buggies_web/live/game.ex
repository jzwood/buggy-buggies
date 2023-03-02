defmodule LiveBuggiesWeb.GameComponent do
  use Phoenix.Component

  def tile(%{cell: cell} = assigns) do
    case cell do
      :wall -> ~H"<.wall x={@x} y={@y} />"
      :water -> ~H"<.water x={@x} y={@y} />"
      :coin -> ~H"<.coin x={@x} y={@y} />"
      :crate -> ~H"<.crate x={@x} y={@y} />"
      :portal -> ~H"<.portal x={@x} y={@y} />"
      :tree -> ~H"<.tree x={@x} y={@y} />"
      _ -> ~H""
    end
  end

  defp wall(assigns) do
    ~H"""
    <rect
      class="wall"
      x={ @x }
      y={ @y }
      width="1"
      height="1"
      shape-rendering="geometricPrecision"
    />
    """
  end

  defp water(assigns) do
    ~H"""
    <rect
      class="water"
      x={ @x }
      y={ @y }
      width="1"
      height="1"
      shape-rendering="geometricPrecision"
    />
    """
  end

  defp coin(assigns) do
    ~H"""
    <circle
      class="coin"
      cx={ @x + 0.5 }
      cy={ @y + 0.5 }
      r="0.375"
      shape-rendering="geometricPrecision"
    />
    """
  end

  defp crate(assigns) do
    ~H"""
    <rect
      class="crate"
      x={ @x }
      y={ @y + 0.1 }
      width="1"
      height="0.8"
      shape-rendering="geometricPrecision"
    />
    """
  end

  defp portal(assigns) do
    ~H"""
    <ellipse
      class="portal"
      cx={ @x + 0.5 }
      cy={ @y + 0.5 }
      rx="0.4"
      ry="0.5"
    />
    """
  end

  defp tree(assigns) do
    ~H"""
    <polygon
      class="tree"
      points={"#{@x},#{@y + 1} #{@x + 0.5},#{@y} #{@x + 1},#{@y + 1}"}
    />
    """
  end

  def tire_tracks(assigns) do
    ~H"""
      <line
        class="tire-tracks"
        x1={@x1}
        y1={@y1}
        x2={@x2}
        y2={@y2}
        fill="none"
        stroke="dimgrey"
        stroke-width="0.1"
        stroke-linejoin="round"
        stroke-linecap="round"
      />
    """
  end

  def player(assigns) do
    ~H"""
    <g
    class="buggy"
    transform-origin={"#{@x + 0.5}px #{@y + 0.5}px"}
    style={"transform: rotate(#{@orientation}deg);"}
    >
      <rect
        class="buggy"
        x={@x + 0.25}
        y={@y}
        width="0.5"
        height="1"
        fill="red"
        shape-rendering="geometricPrecision"
      />
      <rect
        class="buggy"
        x={@x + 0.05}
        y={@y + 0.1}
        width="0.2"
        height="0.3"
        fill="black"
        shape-rendering="geometricPrecision"
      />
      <rect
        class="buggy"
        x={@x + 0.75}
        y={@y + 0.1}
        width="0.2"
        height="0.3"
        fill="black"
        shape-rendering="geometricPrecision"
      />
      <rect
        class="buggy"
        x={@x + 0.05}
        y={@y + 0.6}
        width="0.2"
        height="0.3"
        fill="black"
        shape-rendering="geometricPrecision"
      />
      <rect
        class="buggy"
        x={@x + 0.75}
        y={@y + 0.6}
        width="0.2"
        height="0.3"
        fill="black"
        shape-rendering="geometricPrecision"
      />
    </g>
    """
  end
end
