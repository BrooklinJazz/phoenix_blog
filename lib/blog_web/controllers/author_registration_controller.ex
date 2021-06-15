defmodule BlogWeb.AuthorRegistrationController do
  use BlogWeb, :controller

  alias Blog.Accounts
  alias Blog.Accounts.Author
  alias BlogWeb.AuthorAuth

  def new(conn, _params) do
    changeset = Accounts.change_author_registration(%Author{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"author" => author_params}) do
    case Accounts.register_author(author_params) do
      {:ok, author} ->
        {:ok, _} =
          Accounts.deliver_author_confirmation_instructions(
            author,
            &Routes.author_confirmation_url(conn, :confirm, &1)
          )

        conn
        |> put_flash(:info, "Author created successfully.")
        |> AuthorAuth.log_in_author(author)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
end
