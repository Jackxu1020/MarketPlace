defmodule Backend.Repo.Migrations.CreateOrders do
  use Ecto.Migration

  def change do
    create table(:orders) do
      add :side, :string, null: false  # "buy" or "sell"
      add :price, :decimal, precision: 15, scale: 2, null: false
      add :quantity, :bigint, null: false
      add :remaining_quantity, :bigint, null: false
      add :status, :string, null: false, default: "open"  # open, partially_filled, filled, cancelled, expired
      add :expires_at, :utc_datetime

      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :company_id, references(:companies, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:orders, [:user_id])
    create index(:orders, [:company_id])
    create index(:orders, [:company_id, :side, :status])
    create index(:orders, [:status, :expires_at])
  end
end
