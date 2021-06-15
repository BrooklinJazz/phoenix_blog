defmodule BlogWeb.PostLive do
  use BlogWeb, :live_view
  alias Blog.Posts

  def mount(_params, _session, socket) do
    {:ok, fetch(socket)}
  end

  defp fetch(socket) do
    assign(socket, posts: Posts.list_posts())
  end

  def handle_event("add", %{"post" => post}, socket) do
    Posts.create_post(post)
  end
end
