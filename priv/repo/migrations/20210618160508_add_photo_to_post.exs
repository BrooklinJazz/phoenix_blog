defmodule Blog.Repo.Migrations.AddPhotoToPost do
  use Ecto.Migration

  def change do
    alter table("posts") do
      add :link, :string
    end
  end
end
