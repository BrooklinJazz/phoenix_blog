defmodule BlogWeb.AuthorResetPasswordControllerTest do
  use BlogWeb.ConnCase, async: true

  alias Blog.Accounts
  alias Blog.Repo
  import Blog.AccountsFixtures

  setup do
    %{author: author_fixture()}
  end

  describe "GET /authors/reset_password" do
    test "renders the reset password page", %{conn: conn} do
      conn = get(conn, Routes.author_reset_password_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "<h1>Forgot your password?</h1>"
    end
  end

  describe "POST /authors/reset_password" do
    @tag :capture_log
    test "sends a new reset password token", %{conn: conn, author: author} do
      conn =
        post(conn, Routes.author_reset_password_path(conn, :create), %{
          "author" => %{"email" => author.email}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      assert Repo.get_by!(Accounts.AuthorToken, author_id: author.id).context == "reset_password"
    end

    test "does not send reset password token if email is invalid", %{conn: conn} do
      conn =
        post(conn, Routes.author_reset_password_path(conn, :create), %{
          "author" => %{"email" => "unknown@example.com"}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      assert Repo.all(Accounts.AuthorToken) == []
    end
  end

  describe "GET /authors/reset_password/:token" do
    setup %{author: author} do
      token =
        extract_author_token(fn url ->
          Accounts.deliver_author_reset_password_instructions(author, url)
        end)

      %{token: token}
    end

    test "renders reset password", %{conn: conn, token: token} do
      conn = get(conn, Routes.author_reset_password_path(conn, :edit, token))
      assert html_response(conn, 200) =~ "<h1>Reset password</h1>"
    end

    test "does not render reset password with invalid token", %{conn: conn} do
      conn = get(conn, Routes.author_reset_password_path(conn, :edit, "oops"))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "Reset password link is invalid or it has expired"
    end
  end

  describe "PUT /authors/reset_password/:token" do
    setup %{author: author} do
      token =
        extract_author_token(fn url ->
          Accounts.deliver_author_reset_password_instructions(author, url)
        end)

      %{token: token}
    end

    test "resets password once", %{conn: conn, author: author, token: token} do
      conn =
        put(conn, Routes.author_reset_password_path(conn, :update, token), %{
          "author" => %{
            "password" => "new valid password",
            "password_confirmation" => "new valid password"
          }
        })

      assert redirected_to(conn) == Routes.author_session_path(conn, :new)
      refute get_session(conn, :author_token)
      assert get_flash(conn, :info) =~ "Password reset successfully"
      assert Accounts.get_author_by_email_and_password(author.email, "new valid password")
    end

    test "does not reset password on invalid data", %{conn: conn, token: token} do
      conn =
        put(conn, Routes.author_reset_password_path(conn, :update, token), %{
          "author" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      response = html_response(conn, 200)
      assert response =~ "<h1>Reset password</h1>"
      assert response =~ "should be at least 12 character(s)"
      assert response =~ "does not match password"
    end

    test "does not reset password with invalid token", %{conn: conn} do
      conn = put(conn, Routes.author_reset_password_path(conn, :update, "oops"))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "Reset password link is invalid or it has expired"
    end
  end
end
