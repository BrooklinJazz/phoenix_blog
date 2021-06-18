defmodule BlogWeb.AuthorPostsController do
  use BlogWeb, :controller
  alias Blog.Posts
  alias Blog.Posts.Post
  alias Blog.Accounts

  defp get_current_author(conn) do
    conn
    |> get_session(:author_token)
    |> Accounts.get_author_by_session_token()
  end

  def index(conn, %{"author_id" => author_id}) do
    posts = Posts.list_posts(author_id)
    author = Accounts.get_client_safe_author!(author_id)
    render(conn, "index.html", posts: posts, author: author)
  end

  def show(conn, %{"post_id" => post_id}) do
    post = Posts.get_post!(post_id)
    current_author = get_current_author(conn)
    author = Accounts.get_client_safe_author!(post.author_id)
    render(conn, "show.html", post: post, author: author, current_author: current_author)
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

  def edit(conn, %{"post_id" => post_id}) do
    changeset = Posts.change_post(%Post{})
    post = Posts.get_post!(post_id)
    render(conn, "edit.html", changeset: changeset, current_post: post)
  end

  def update(conn, %{"post_id" => post_id, "post" => post_params}) do
    previous_post = Posts.get_post!(post_id)

    case Posts.update_post(previous_post, post_params) do
      {:ok, _post} ->
        conn
        |> put_flash(:info, "Post updated successfully.")
        |> show(%{"post_id" => post_id})

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", changeset: changeset, current_post: previous_post)
    end
  end

  def delete(conn, %{"post_id" => post_id}) do
    post = Posts.get_post!(post_id)
    current_author = get_current_author(conn)

    case Posts.delete_post(post) do
      {:ok, _post} ->
        conn
        |> put_flash(:info, "Post deleted successfully.")
        |> index(%{"author_id" => current_author.id})

      {:error, %Ecto.Changeset{} = _changeset} ->
        edit(conn, %{"post_id" => post_id})
    end
  end
end
