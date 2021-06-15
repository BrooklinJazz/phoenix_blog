defmodule BlogWeb.AuthorSettingsController do
  use BlogWeb, :controller

  alias Blog.Accounts
  alias BlogWeb.AuthorAuth

  plug :assign_email_and_password_changesets

  def edit(conn, _params) do
    render(conn, "edit.html")
  end

  def update(conn, %{"action" => "update_email"} = params) do
    %{"current_password" => password, "author" => author_params} = params
    author = conn.assigns.current_author

    case Accounts.apply_author_email(author, password, author_params) do
      {:ok, applied_author} ->
        Accounts.deliver_update_email_instructions(
          applied_author,
          author.email,
          &Routes.author_settings_url(conn, :confirm_email, &1)
        )

        conn
        |> put_flash(
          :info,
          "A link to confirm your email change has been sent to the new address."
        )
        |> redirect(to: Routes.author_settings_path(conn, :edit))

      {:error, changeset} ->
        render(conn, "edit.html", email_changeset: changeset)
    end
  end

  def update(conn, %{"action" => "update_password"} = params) do
    %{"current_password" => password, "author" => author_params} = params
    author = conn.assigns.current_author

    case Accounts.update_author_password(author, password, author_params) do
      {:ok, author} ->
        conn
        |> put_flash(:info, "Password updated successfully.")
        |> put_session(:author_return_to, Routes.author_settings_path(conn, :edit))
        |> AuthorAuth.log_in_author(author)

      {:error, changeset} ->
        render(conn, "edit.html", password_changeset: changeset)
    end
  end

  def confirm_email(conn, %{"token" => token}) do
    case Accounts.update_author_email(conn.assigns.current_author, token) do
      :ok ->
        conn
        |> put_flash(:info, "Email changed successfully.")
        |> redirect(to: Routes.author_settings_path(conn, :edit))

      :error ->
        conn
        |> put_flash(:error, "Email change link is invalid or it has expired.")
        |> redirect(to: Routes.author_settings_path(conn, :edit))
    end
  end

  defp assign_email_and_password_changesets(conn, _opts) do
    author = conn.assigns.current_author

    conn
    |> assign(:email_changeset, Accounts.change_author_email(author))
    |> assign(:password_changeset, Accounts.change_author_password(author))
  end
end
