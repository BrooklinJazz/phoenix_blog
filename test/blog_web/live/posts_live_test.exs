defmodule BlogWeb.PostsLiveTest do
  use BlogWeb.ConnCase

  import Phoenix.LiveViewTest
  use Blog.PostsFixtures
  import Blog.PostsFixtures

  test "disconnected and connected render", %{conn: conn, post: post} do
    {:ok, page_live, disconnected_html} = live(conn, "/")

    assert disconnected_html =~ post.title
    assert render(page_live) =~ post.title
  end
end
