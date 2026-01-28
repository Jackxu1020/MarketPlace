defmodule Backend.Marketplace.Company do
  use Ecto.Schema
  import Ecto.Changeset

  schema "companies" do
    field :name, :string
    field :ticker, :string
    field :description, :string
    field :sector, :string
    field :valuation, :decimal
    field :total_shares, :integer

    has_many :orders, Backend.Marketplace.Order
    has_many :trades, Backend.Marketplace.Trade
    has_many :holdings, Backend.Accounts.Holding

    timestamps()
  end

  def changeset(company, attrs) do
    company
    |> cast(attrs, [:name, :ticker, :description, :sector, :valuation, :total_shares])
    |> validate_required([:name, :ticker, :sector, :valuation, :total_shares])
    |> unique_constraint(:ticker)
    |> validate_number(:valuation, greater_than: 0)
    |> validate_number(:total_shares, greater_than: 0)
  end
end
