defmodule BlogWeb.AuthorConfirmationControllerTest do
  use BlogWeb.ConnCase, async: true

  alias Blog.Accounts
  alias Blog.Repo
  import Blog.AccountsFixtures

  setup do
    %{author: author_fixture()}
  end

  describe "GET /authors/confirm" do
    test "renders the confirmation page", %{conn: conn} do
      conn = get(conn, Routes.author_confirmation_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "<h1>Resend confirmation instructions</h1>"
    end
  end

  describe "POST /authors/confirm" do
    @tag :capture_log
    test "sends a new confirmation token", %{conn: conn, author: author} do
      conn =
        post(conn, Routes.author_confirmation_path(conn, :create), %{
          "author" => %{"email" => author.email}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      assert Repo.get_by!(Accounts.AuthorToken, author_id: author.id).context == "confirm"
    end

    test "does not send confirmation token if Author is confirmed", %{conn: conn, author: author} do
      Repo.update!(Accounts.Author.confirm_changeset(author))

      conn =
        post(conn, Routes.author_confirmation_path(conn, :create), %{
          "author" => %{"email" => author.email}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      refute Repo.get_by(Accounts.AuthorToken, author_id: author.id)
    end

    test "does not send confirmation token if email is invalid", %{conn: conn} do
      conn =
        post(conn, Routes.author_confirmation_path(conn, :create), %{
          "author" => %{"email" => "unknown@example.com"}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      assert Repo.all(Accounts.AuthorToken) == []
    end
  end

  describe "GET /authors/confirm/:token" do
    test "confirms the given token once", %{conn: conn, author: author} do
      token =
        extract_author_token(fn url ->
          Accounts.deliver_author_confirmation_instructions(author, url)
        end)

      conn = get(conn, Routes.author_confirmation_path(conn, :confirm, token))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "Author confirmed successfully"
      assert Accounts.get_author!(author.id).confirmed_at
      refute get_session(conn, :author_token)
      assert Repo.all(Accounts.AuthorToken) == []

      # When not logged in
      conn = get(conn, Routes.author_confirmation_path(conn, :confirm, token))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "Author confirmation link is invalid or it has expired"

      # When logged in
      conn =
        build_conn()
        |> log_in_author(author)
        |> get(Routes.author_confirmation_path(conn, :confirm, token))

      assert redirected_to(conn) == "/"
      refute get_flash(conn, :error)
    end

    test "does not confirm email with invalid token", %{conn: conn, author: author} do
      conn = get(conn, Routes.author_confirmation_path(conn, :confirm, "oops"))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "Author confirmation link is invalid or it has expired"
      refute Accounts.get_author!(author.id).confirmed_at
    end
  end
end
