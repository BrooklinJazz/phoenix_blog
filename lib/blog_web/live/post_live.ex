defmodule BlogWeb.PostLive do
  use BlogWeb, :live_view
  alias Blog.Posts

  def mount(_params, _session, socket) do
    Posts.subscribe()
    {:ok, fetch(socket)}
  end

  def handle_info({Posts, [:post | _], _}, socket) do
    {:noreply, fetch(socket)}
  end

  defp fetch(socket) do
    assign(socket, posts: Posts.list_posts())
  end

  def handle_event("add", %{"post" => post}, socket) do
    Posts.create_post(post)
    {:noreply, fetch(socket)}
  end
end
