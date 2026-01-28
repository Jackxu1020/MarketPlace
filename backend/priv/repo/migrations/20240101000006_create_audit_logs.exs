defmodule Backend.Repo.Migrations.CreateAuditLogs do
  use Ecto.Migration

  def change do
    create table(:audit_logs) do
      add :action, :string, null: false
      add :entity_type, :string, null: false
      add :entity_id, :bigint, null: false
      add :metadata, :map, default: %{}
      add :user_id, references(:users, on_delete: :nilify_all)

      timestamps(updated_at: false)
    end

    create index(:audit_logs, [:entity_type, :entity_id])
    create index(:audit_logs, [:user_id])
    create index(:audit_logs, [:action])
  end
end
