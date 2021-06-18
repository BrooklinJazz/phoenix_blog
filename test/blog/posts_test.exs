defmodule Blog.PostsTest do
  use Blog.DataCase

  alias Blog.Posts
  use Blog.PostsFixtures
  import Blog.PostsFixtures

  describe "posts" do
    alias Blog.Posts.Post
    @invalid_attrs %{body: nil, subtitle: nil, tags: nil, title: nil, author_id: nil}

    test "list_posts/0 returns all posts", %{post: post} do
      assert Posts.list_posts() == [post]
    end

    test "get_post!/1 returns the post with given id", %{post: post} do
      assert Posts.get_post!(post.id) == post
    end

    test "create_post/1 with valid data creates a post", %{
      author: author,
      valid_attrs: valid_attrs
    } do
      assert {:ok, %Post{} = post} =
               Posts.create_post(Map.merge(valid_attrs, %{author_id: author.id}))

      assert post.body == "some body"
      assert post.subtitle == "some subtitle"
      assert post.tags == []
      assert post.title == "some title"
    end

    test "create_post/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Posts.create_post(@invalid_attrs)
    end

    test "update_post/2 with valid data updates the post", %{
      update_attrs: update_attrs,
      post: post
    } do
      assert {:ok, %Post{} = post} = Posts.update_post(post, update_attrs)
      assert post.body == "some updated body"
      assert post.subtitle == "some updated subtitle"
      assert post.tags == []
      assert post.title == "some updated title"
    end

    test "update_post/2 with invalid data returns error changeset", %{post: post} do
      assert {:error, %Ecto.Changeset{}} = Posts.update_post(post, @invalid_attrs)
      assert post == Posts.get_post!(post.id)
    end

    test "delete_post/1 deletes the post", %{post: post} do
      assert {:ok, %Post{}} = Posts.delete_post(post)
      assert_raise Ecto.NoResultsError, fn -> Posts.get_post!(post.id) end
    end

    test "change_post/1 returns a post changeset", %{post: post} do
      assert %Ecto.Changeset{} = Posts.change_post(post)
    end
  end
end
