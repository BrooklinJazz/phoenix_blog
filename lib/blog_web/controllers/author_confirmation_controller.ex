defmodule BlogWeb.AuthorConfirmationController do
  use BlogWeb, :controller

  alias Blog.Accounts

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"author" => %{"email" => email}}) do
    if author = Accounts.get_author_by_email(email) do
      Accounts.deliver_author_confirmation_instructions(
        author,
        &Routes.author_confirmation_url(conn, :confirm, &1)
      )
    end

    # Regardless of the outcome, show an impartial success/error message.
    conn
    |> put_flash(
      :info,
      "If your email is in our system and it has not been confirmed yet, " <>
        "you will receive an email with instructions shortly."
    )
    |> redirect(to: "/")
  end

  # Do not log in the author after confirmation to avoid a
  # leaked token giving the author access to the account.
  def confirm(conn, %{"token" => token}) do
    case Accounts.confirm_author(token) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Author confirmed successfully.")
        |> redirect(to: "/")

      :error ->
        # If there is a current author and the account was already confirmed,
        # then odds are that the confirmation link was already visited, either
        # by some automation or by the author themselves, so we redirect without
        # a warning message.
        case conn.assigns do
          %{current_author: %{confirmed_at: confirmed_at}} when not is_nil(confirmed_at) ->
            redirect(conn, to: "/")

          %{} ->
            conn
            |> put_flash(:error, "Author confirmation link is invalid or it has expired.")
            |> redirect(to: "/")
        end
    end
  end
end
