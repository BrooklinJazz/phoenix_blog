defmodule BlogWeb.AuthorPostsController do
  use BlogWeb, :controller
  alias Blog.Posts

  def index(conn, %{"author_id" => author_id}) do
    posts = Posts.list_posts(author_id)
    render(conn, "index.html", posts: posts)
  end
end
