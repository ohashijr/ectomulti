defmodule EctoMulti.Repo.Migrations.CreateMembership do
  use Ecto.Migration

  def change do
    create table(:memberships) do
      add :role, :string
      add :user_id, references(:users, on_delete: :nothing)
      add :account_id, references(:accounts, on_delete: :nothing)

      timestamps()
    end
    create index(:memberships, [:user_id])
    create index(:memberships, [:account_id])

  end
end
