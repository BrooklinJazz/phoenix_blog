defmodule BlogWeb.AuthorAuthTest do
  use BlogWeb.ConnCase, async: true

  alias Blog.Accounts
  alias BlogWeb.AuthorAuth
  import Blog.AccountsFixtures

  @remember_me_cookie "_blog_web_author_remember_me"

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, BlogWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    %{author: author_fixture(), conn: conn}
  end

  describe "log_in_author/3" do
    test "stores the author token in the session", %{conn: conn, author: author} do
      conn = AuthorAuth.log_in_author(conn, author)
      assert token = get_session(conn, :author_token)
      assert get_session(conn, :live_socket_id) == "authors_sessions:#{Base.url_encode64(token)}"
      assert redirected_to(conn) == "/"
      assert Accounts.get_author_by_session_token(token)
    end

    test "clears everything previously stored in the session", %{conn: conn, author: author} do
      conn = conn |> put_session(:to_be_removed, "value") |> AuthorAuth.log_in_author(author)
      refute get_session(conn, :to_be_removed)
    end

    test "redirects to the configured path", %{conn: conn, author: author} do
      conn = conn |> put_session(:author_return_to, "/hello") |> AuthorAuth.log_in_author(author)
      assert redirected_to(conn) == "/hello"
    end

    test "writes a cookie if remember_me is configured", %{conn: conn, author: author} do
      conn = conn |> fetch_cookies() |> AuthorAuth.log_in_author(author, %{"remember_me" => "true"})
      assert get_session(conn, :author_token) == conn.cookies[@remember_me_cookie]

      assert %{value: signed_token, max_age: max_age} = conn.resp_cookies[@remember_me_cookie]
      assert signed_token != get_session(conn, :author_token)
      assert max_age == 5_184_000
    end
  end

  describe "logout_author/1" do
    test "erases session and cookies", %{conn: conn, author: author} do
      author_token = Accounts.generate_author_session_token(author)

      conn =
        conn
        |> put_session(:author_token, author_token)
        |> put_req_cookie(@remember_me_cookie, author_token)
        |> fetch_cookies()
        |> AuthorAuth.log_out_author()

      refute get_session(conn, :author_token)
      refute conn.cookies[@remember_me_cookie]
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == "/"
      refute Accounts.get_author_by_session_token(author_token)
    end

    test "broadcasts to the given live_socket_id", %{conn: conn} do
      live_socket_id = "authors_sessions:abcdef-token"
      BlogWeb.Endpoint.subscribe(live_socket_id)

      conn
      |> put_session(:live_socket_id, live_socket_id)
      |> AuthorAuth.log_out_author()

      assert_receive %Phoenix.Socket.Broadcast{
        event: "disconnect",
        topic: "authors_sessions:abcdef-token"
      }
    end

    test "works even if author is already logged out", %{conn: conn} do
      conn = conn |> fetch_cookies() |> AuthorAuth.log_out_author()
      refute get_session(conn, :author_token)
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == "/"
    end
  end

  describe "fetch_current_author/2" do
    test "authenticates author from session", %{conn: conn, author: author} do
      author_token = Accounts.generate_author_session_token(author)
      conn = conn |> put_session(:author_token, author_token) |> AuthorAuth.fetch_current_author([])
      assert conn.assigns.current_author.id == author.id
    end

    test "authenticates author from cookies", %{conn: conn, author: author} do
      logged_in_conn =
        conn |> fetch_cookies() |> AuthorAuth.log_in_author(author, %{"remember_me" => "true"})

      author_token = logged_in_conn.cookies[@remember_me_cookie]
      %{value: signed_token} = logged_in_conn.resp_cookies[@remember_me_cookie]

      conn =
        conn
        |> put_req_cookie(@remember_me_cookie, signed_token)
        |> AuthorAuth.fetch_current_author([])

      assert get_session(conn, :author_token) == author_token
      assert conn.assigns.current_author.id == author.id
    end

    test "does not authenticate if data is missing", %{conn: conn, author: author} do
      _ = Accounts.generate_author_session_token(author)
      conn = AuthorAuth.fetch_current_author(conn, [])
      refute get_session(conn, :author_token)
      refute conn.assigns.current_author
    end
  end

  describe "redirect_if_author_is_authenticated/2" do
    test "redirects if author is authenticated", %{conn: conn, author: author} do
      conn = conn |> assign(:current_author, author) |> AuthorAuth.redirect_if_author_is_authenticated([])
      assert conn.halted
      assert redirected_to(conn) == "/"
    end

    test "does not redirect if author is not authenticated", %{conn: conn} do
      conn = AuthorAuth.redirect_if_author_is_authenticated(conn, [])
      refute conn.halted
      refute conn.status
    end
  end

  describe "require_authenticated_author/2" do
    test "redirects if author is not authenticated", %{conn: conn} do
      conn = conn |> fetch_flash() |> AuthorAuth.require_authenticated_author([])
      assert conn.halted
      assert redirected_to(conn) == Routes.author_session_path(conn, :new)
      assert get_flash(conn, :error) == "You must log in to access this page."
    end

    test "stores the path to redirect to on GET", %{conn: conn} do
      halted_conn =
        %{conn | request_path: "/foo", query_string: ""}
        |> fetch_flash()
        |> AuthorAuth.require_authenticated_author([])

      assert halted_conn.halted
      assert get_session(halted_conn, :author_return_to) == "/foo"

      halted_conn =
        %{conn | request_path: "/foo", query_string: "bar=baz"}
        |> fetch_flash()
        |> AuthorAuth.require_authenticated_author([])

      assert halted_conn.halted
      assert get_session(halted_conn, :author_return_to) == "/foo?bar=baz"

      halted_conn =
        %{conn | request_path: "/foo?bar", method: "POST"}
        |> fetch_flash()
        |> AuthorAuth.require_authenticated_author([])

      assert halted_conn.halted
      refute get_session(halted_conn, :author_return_to)
    end

    test "does not redirect if author is authenticated", %{conn: conn, author: author} do
      conn = conn |> assign(:current_author, author) |> AuthorAuth.require_authenticated_author([])
      refute conn.halted
      refute conn.status
    end
  end
end
