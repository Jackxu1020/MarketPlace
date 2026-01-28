defmodule Backend.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string
    field :email, :string
    field :cash_balance, :decimal, default: Decimal.new(0)

    has_many :holdings, Backend.Accounts.Holding
    has_many :orders, Backend.Marketplace.Order

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :cash_balance])
    |> validate_required([:name, :email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/)
    |> unique_constraint(:email)
    |> validate_number(:cash_balance, greater_than_or_equal_to: 0)
  end
end
