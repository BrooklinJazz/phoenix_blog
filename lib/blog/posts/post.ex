defmodule Blog.Posts.Post do
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field :body, :string, default: ""
    field :subtitle, :string, default: ""
    field :tags, {:array, :string}, default: []
    field :title, :string
    field :author_id, :id

    timestamps()
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :subtitle, :body, :tags])
    |> validate_required([:title])
  end
end
