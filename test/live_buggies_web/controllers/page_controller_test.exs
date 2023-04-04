defmodule LiveBuggiesWeb.PageControllerTest do
  use LiveBuggiesWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "buggy buggies"
  end
end
