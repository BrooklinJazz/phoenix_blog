defmodule BlogWeb.AuthorSettingsControllerTest do
  use BlogWeb.ConnCase, async: true

  alias Blog.Accounts
  import Blog.AccountsFixtures

  setup :register_and_log_in_author

  describe "GET /authors/settings" do
    test "renders settings page", %{conn: conn} do
      conn = get(conn, Routes.author_settings_path(conn, :edit))
      response = html_response(conn, 200)
      assert response =~ "<h1>Settings</h1>"
    end

    test "redirects if author is not logged in" do
      conn = build_conn()
      conn = get(conn, Routes.author_settings_path(conn, :edit))
      assert redirected_to(conn) == Routes.author_session_path(conn, :new)
    end
  end

  describe "PUT /authors/settings (change password form)" do
    test "updates the author password and resets tokens", %{conn: conn, author: author} do
      new_password_conn =
        put(conn, Routes.author_settings_path(conn, :update), %{
          "action" => "update_password",
          "current_password" => valid_author_password(),
          "author" => %{
            "password" => "new valid password",
            "password_confirmation" => "new valid password"
          }
        })

      assert redirected_to(new_password_conn) == Routes.author_settings_path(conn, :edit)
      assert get_session(new_password_conn, :author_token) != get_session(conn, :author_token)
      assert get_flash(new_password_conn, :info) =~ "Password updated successfully"
      assert Accounts.get_author_by_email_and_password(author.email, "new valid password")
    end

    test "does not update password on invalid data", %{conn: conn} do
      old_password_conn =
        put(conn, Routes.author_settings_path(conn, :update), %{
          "action" => "update_password",
          "current_password" => "invalid",
          "author" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      response = html_response(old_password_conn, 200)
      assert response =~ "<h1>Settings</h1>"
      assert response =~ "should be at least 12 character(s)"
      assert response =~ "does not match password"
      assert response =~ "is not valid"

      assert get_session(old_password_conn, :author_token) == get_session(conn, :author_token)
    end
  end

  describe "PUT /authors/settings (change email form)" do
    @tag :capture_log
    test "updates the author email", %{conn: conn, author: author} do
      conn =
        put(conn, Routes.author_settings_path(conn, :update), %{
          "action" => "update_email",
          "current_password" => valid_author_password(),
          "author" => %{"email" => unique_author_email()}
        })

      assert redirected_to(conn) == Routes.author_settings_path(conn, :edit)
      assert get_flash(conn, :info) =~ "A link to confirm your email"
      assert Accounts.get_author_by_email(author.email)
    end

    test "does not update email on invalid data", %{conn: conn} do
      conn =
        put(conn, Routes.author_settings_path(conn, :update), %{
          "action" => "update_email",
          "current_password" => "invalid",
          "author" => %{"email" => "with spaces"}
        })

      response = html_response(conn, 200)
      assert response =~ "<h1>Settings</h1>"
      assert response =~ "must have the @ sign and no spaces"
      assert response =~ "is not valid"
    end
  end

  describe "GET /authors/settings/confirm_email/:token" do
    setup %{author: author} do
      email = unique_author_email()

      token =
        extract_author_token(fn url ->
          Accounts.deliver_update_email_instructions(%{author | email: email}, author.email, url)
        end)

      %{token: token, email: email}
    end

    test "updates the author email once", %{conn: conn, author: author, token: token, email: email} do
      conn = get(conn, Routes.author_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == Routes.author_settings_path(conn, :edit)
      assert get_flash(conn, :info) =~ "Email changed successfully"
      refute Accounts.get_author_by_email(author.email)
      assert Accounts.get_author_by_email(email)

      conn = get(conn, Routes.author_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == Routes.author_settings_path(conn, :edit)
      assert get_flash(conn, :error) =~ "Email change link is invalid or it has expired"
    end

    test "does not update email with invalid token", %{conn: conn, author: author} do
      conn = get(conn, Routes.author_settings_path(conn, :confirm_email, "oops"))
      assert redirected_to(conn) == Routes.author_settings_path(conn, :edit)
      assert get_flash(conn, :error) =~ "Email change link is invalid or it has expired"
      assert Accounts.get_author_by_email(author.email)
    end

    test "redirects if author is not logged in", %{token: token} do
      conn = build_conn()
      conn = get(conn, Routes.author_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == Routes.author_session_path(conn, :new)
    end
  end
end
