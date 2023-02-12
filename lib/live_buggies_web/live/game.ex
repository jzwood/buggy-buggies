  defmodule LiveBuggiesWeb.GameComponent do
  use Phoenix.Component

    def background(assigns) do
      ~H"""
        <rect x="0" y="0" width={@width} height={@height} fill="gray" shape-rendering='optimizeSpeed' />
      """
    end

  def tile(%{cell: cell} = assigns) do
    case cell do
      :wall -> ~H"<.wall x={@x} y={@y} />"
      :water -> ~H"<.water x={@x} y={@y} />"
      :coin -> ~H"<.coin x={@x} y={@y} />"
      :crate -> ~H"<.crate x={@x} y={@y} />"
      :portal -> ~H"<.portal x={@x} y={@y} />"
      :trap -> ~H"<.trap x={@x} y={@y} />"
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
      fill="#CCC"
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
        fill="#005377"
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
        fill="#F1A208"
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
        fill="#644432"
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
        fill="#7D00C5"
      />
      """
    end

    defp trap(assigns) do
      ~H"""
      <polygon
        class="trap"
        points={"#{@x},#{@y + 1} #{@x + 0.5},#{@y} #{@x + 1},#{@y + 1}"}
      />
      """
    end


    def player(assigns) do
      ~H"""
      <g class="buggy-n">
        <rect
          class="crate"
          x="13.25"
          y="11"
          width="0.5"
          height="1"
          fill="red"
          shape-rendering="geometricPrecision"
        />
        <rect
          class="crate"
          x="13.05"
          y="11.1"
          width="0.2"
          height="0.3"
          fill="black"
          shape-rendering="geometricPrecision"
        />
        <rect
          class="crate"
          x="13.75"
          y="11.1"
          width="0.2"
          height="0.3"
          fill="black"
          shape-rendering="geometricPrecision"
        />
        <rect
          class="crate"
          x="13.05"
          y="11.6"
          width="0.2"
          height="0.3"
          fill="black"
          shape-rendering="geometricPrecision"
        />
        <rect
          class="crate"
          x="13.75"
          y="11.6"
          width="0.2"
          height="0.3"
          fill="black"
          shape-rendering="geometricPrecision"
        />
      </g>
      """
    end
end
