# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Blog.Repo.insert!(%Blog.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Blog.Repo
alias Blog.Accounts
alias Blog.Accounts.Author
alias Blog.Posts
alias Blog.Posts.Post

Repo.delete_all(Post)
Repo.delete_all(Author)

{:ok, author} =
  Accounts.register_author(%{
    name: "test author",
    email: "test@test.ca",
    password: "supersecretpassword"
  })

body = for _ <- 1..1000, into: "", do: <<Enum.random('0123456789abcdef ')>>

Enum.each(1..10, fn n ->
  str = to_string(n)

  Posts.create_post(%{
    title: "test title" <> str,
    subtitle: "test subtitle" <> str,
    author_id: author.id,
    body: body,
    tags: ["elixir"]
  })
end)
