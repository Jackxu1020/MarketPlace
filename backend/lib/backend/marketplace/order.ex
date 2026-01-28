defmodule Backend.Marketplace.Order do
  use Ecto.Schema
  import Ecto.Changeset

  @sides ~w(buy sell)
  @statuses ~w(open partially_filled filled cancelled expired)

  schema "orders" do
    field :side, :string
    field :price, :decimal
    field :quantity, :integer
    field :remaining_quantity, :integer
    field :status, :string, default: "open"
    field :expires_at, :utc_datetime

    belongs_to :user, Backend.Accounts.User
    belongs_to :company, Backend.Marketplace.Company

    timestamps()
  end

  def changeset(order, attrs) do
    order
    |> cast(attrs, [:side, :price, :quantity, :remaining_quantity, :status, :expires_at, :user_id, :company_id])
    |> validate_required([:side, :price, :quantity, :user_id, :company_id])
    |> validate_inclusion(:side, @sides)
    |> validate_inclusion(:status, @statuses)
    |> validate_number(:price, greater_than: 0)
    |> validate_number(:quantity, greater_than: 0)
    |> validate_number(:remaining_quantity, greater_than_or_equal_to: 0)
    |> set_remaining_quantity()
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:company_id)
  end

  def status_changeset(order, attrs) do
    order
    |> cast(attrs, [:status, :remaining_quantity])
    |> validate_inclusion(:status, @statuses)
  end

  defp set_remaining_quantity(changeset) do
    case get_change(changeset, :remaining_quantity) do
      nil ->
        case get_change(changeset, :quantity) do
          nil -> changeset
          quantity -> put_change(changeset, :remaining_quantity, quantity)
        end
      _ ->
        changeset
    end
  end

  def open?(%__MODULE__{status: status}), do: status in ["open", "partially_filled"]
  def filled?(%__MODULE__{status: status}), do: status == "filled"
  def cancelled?(%__MODULE__{status: status}), do: status == "cancelled"
  def expired?(%__MODULE__{status: status}), do: status == "expired"
end
