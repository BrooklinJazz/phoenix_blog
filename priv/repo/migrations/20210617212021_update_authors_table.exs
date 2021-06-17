defmodule Blog.Repo.Migrations.UpdateAuthorsTable do
  use Ecto.Migration

  def change do
    alter table("authors") do
      add :name, :string
    end
  end
end
