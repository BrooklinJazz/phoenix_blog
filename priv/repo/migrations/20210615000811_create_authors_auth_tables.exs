defmodule Blog.Repo.Migrations.CreateAuthorsAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:authors) do
      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime
      timestamps()
    end

    create unique_index(:authors, [:email])

    create table(:authors_tokens) do
      add :author_id, references(:authors, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      timestamps(updated_at: false)
    end

    create index(:authors_tokens, [:author_id])
    create unique_index(:authors_tokens, [:context, :token])
  end
end
