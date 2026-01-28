defmodule Backend.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string, null: false
      add :email, :string, null: false
      add :cash_balance, :decimal, precision: 15, scale: 2, null: false, default: 0

      timestamps()
    end

    create unique_index(:users, [:email])
  end
end
