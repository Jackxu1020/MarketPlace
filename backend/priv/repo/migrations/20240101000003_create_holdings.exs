defmodule Backend.Repo.Migrations.CreateHoldings do
  use Ecto.Migration

  def change do
    create table(:holdings) do
      add :quantity, :bigint, null: false, default: 0
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :company_id, references(:companies, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:holdings, [:user_id])
    create index(:holdings, [:company_id])
    create unique_index(:holdings, [:user_id, :company_id])
  end
end
