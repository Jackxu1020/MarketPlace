defmodule Backend.Marketplace.Trade do
  use Ecto.Schema
  import Ecto.Changeset

  schema "trades" do
    field :price, :decimal
    field :quantity, :integer

    belongs_to :buy_order, Backend.Marketplace.Order
    belongs_to :sell_order, Backend.Marketplace.Order
    belongs_to :company, Backend.Marketplace.Company
    belongs_to :buyer, Backend.Accounts.User
    belongs_to :seller, Backend.Accounts.User

    timestamps()
  end

  def changeset(trade, attrs) do
    trade
    |> cast(attrs, [:price, :quantity, :buy_order_id, :sell_order_id, :company_id, :buyer_id, :seller_id])
    |> validate_required([:price, :quantity, :buy_order_id, :sell_order_id, :company_id, :buyer_id, :seller_id])
    |> validate_number(:price, greater_than: 0)
    |> validate_number(:quantity, greater_than: 0)
    |> foreign_key_constraint(:buy_order_id)
    |> foreign_key_constraint(:sell_order_id)
    |> foreign_key_constraint(:company_id)
    |> foreign_key_constraint(:buyer_id)
    |> foreign_key_constraint(:seller_id)
  end
end
