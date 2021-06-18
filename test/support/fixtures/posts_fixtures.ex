defmodule Blog.PostsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Blog.Posts` context.
  """
  use ExUnit.CaseTemplate
  alias Blog.Posts
  import Blog.AccountsFixtures

  using do
    quote do
    end
  end

  setup do
    author = author_fixture()

    valid_attrs = %{
      body: "some body",
      subtitle: "some subtitle",
      tags: [],
      title: "some title",
      author_id: author.id
    }

    %{
      author: author,
      valid_attrs: valid_attrs,
      post: post_fixture(valid_attrs),
      update_attrs: %{
        body: "some updated body",
        subtitle: "some updated subtitle",
        tags: [],
        title: "some updated title",
        author_id: author.id
      }
    }
  end

  def post_fixture(attrs \\ %{}) do
    {:ok, post} = Posts.create_post(attrs)

    post
  end
end
