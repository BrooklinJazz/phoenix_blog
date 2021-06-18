defmodule Blog.Posts.Post do
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field :body, :string, default: ""
    field :subtitle, :string, default: ""
    field :tags, {:array, :string}, default: []
    field :title, :string
    field :author_id, :id
    field :link, :string

    timestamps()
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :subtitle, :body, :tags, :author_id, :link])
    |> validate_required([:title, :author_id])
  end
end
