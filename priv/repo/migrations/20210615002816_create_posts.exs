defmodule Blog.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :title, :string
      add :subtitle, :string
      add :body, :text
      add :tags, {:array, :string}
      add :author_id, references(:authors, on_delete: :nothing)

      timestamps()
    end

    create index(:posts, [:author_id])
  end
end
