defmodule BlogWeb.AuthorPostsController do
  use BlogWeb, :controller
  alias Blog.Posts
  alias Blog.Posts.Post
  alias Blog.Accounts

  def index(conn, %{"author_id" => author_id}) do
    posts = Posts.list_posts(author_id)
    render(conn, "index.html", posts: posts)
  end

  def new(conn, _params) do
    changeset = Posts.change_post(%Post{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"post" => post_params}) do
    author_token = get_session(conn, :author_token)
    author = Accounts.get_author_by_session_token(author_token)
    post = Map.merge(post_params, %{"author_id" => author.id})

    case Posts.create_post(post) do
      {:ok, _post} ->
        conn
        |> put_flash(:info, "Post created successfully.")
        |> index(%{"author_id" => author.id})

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
end
