defmodule Backend.Repo.Migrations.CreateTrades do
  use Ecto.Migration

  def change do
    create table(:trades) do
      add :price, :decimal, precision: 15, scale: 2, null: false
      add :quantity, :bigint, null: false

      add :buy_order_id, references(:orders, on_delete: :nilify_all), null: false
      add :sell_order_id, references(:orders, on_delete: :nilify_all), null: false
      add :company_id, references(:companies, on_delete: :delete_all), null: false
      add :buyer_id, references(:users, on_delete: :nilify_all), null: false
      add :seller_id, references(:users, on_delete: :nilify_all), null: false

      timestamps()
    end

    create index(:trades, [:company_id])
    create index(:trades, [:buyer_id])
    create index(:trades, [:seller_id])
    create index(:trades, [:buy_order_id])
    create index(:trades, [:sell_order_id])
  end
end
