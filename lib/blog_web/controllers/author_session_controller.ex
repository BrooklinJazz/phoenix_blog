defmodule BlogWeb.AuthorSessionController do
  use BlogWeb, :controller

  alias Blog.Accounts
  alias BlogWeb.AuthorAuth

  def new(conn, _params) do
    render(conn, "new.html", error_message: nil)
  end

  def create(conn, %{"author" => author_params}) do
    %{"email" => email, "password" => password} = author_params

    if author = Accounts.get_author_by_email_and_password(email, password) do
      AuthorAuth.log_in_author(conn, author, author_params)
    else
      render(conn, "new.html", error_message: "Invalid email or password")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> AuthorAuth.log_out_author()
  end
end
