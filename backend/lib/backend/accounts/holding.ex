defmodule Backend.Accounts.Holding do
  use Ecto.Schema
  import Ecto.Changeset

  schema "holdings" do
    field :quantity, :integer, default: 0

    belongs_to :user, Backend.Accounts.User
    belongs_to :company, Backend.Marketplace.Company

    timestamps()
  end

  def changeset(holding, attrs) do
    holding
    |> cast(attrs, [:quantity, :user_id, :company_id])
    |> validate_required([:quantity, :user_id, :company_id])
    |> validate_number(:quantity, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:company_id)
    |> unique_constraint([:user_id, :company_id])
  end
end
