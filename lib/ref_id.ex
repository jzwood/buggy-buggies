defmodule RefId do
  def gen_id do
    :erlang.make_ref()
    |> :erlang.ref_to_list()
    |> to_string
  end
end
