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

Repo.delete_all(Author)
Repo.delete_all(Post)

{:ok, author} =
  Accounts.register_author(%{
    email: "test@test.ca",
    password: "supersecretpassword"
  })

IO.puts(author.id)

Posts.create_post(%{
  title: "test title",
  subtitle: "test subtitle",
  author_id: author.id,
  body: "test body",
  tags: ["elixir"]
})
