defmodule Backend.Repo.Migrations.CreateCompanies do
  use Ecto.Migration

  def change do
    create table(:companies) do
      add :name, :string, null: false
      add :ticker, :string, null: false
      add :description, :text
      add :sector, :string, null: false
      add :valuation, :decimal, precision: 15, scale: 2, null: false
      add :total_shares, :bigint, null: false

      timestamps()
    end

    create unique_index(:companies, [:ticker])
  end
end
