defmodule SmallID do
  @moduledoc """
  shorter uuid
  """
  def new() do
    String.slice(UUID.uuid4(), 0, 8)
  end
end
