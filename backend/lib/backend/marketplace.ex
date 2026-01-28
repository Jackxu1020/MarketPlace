defmodule Backend.Marketplace do
  @moduledoc """
  The Marketplace context - manages companies, orders, and trades.
  """

  import Ecto.Query
  alias Backend.Repo
  alias Backend.Marketplace.{Company, Order, Trade}

  # Companies

  def list_companies do
    Repo.all(Company)
  end

  def get_company(id) do
    Repo.get(Company, id)
  end

  def get_company!(id) do
    Repo.get!(Company, id)
  end

  def create_company(attrs \\ %{}) do
    %Company{}
    |> Company.changeset(attrs)
    |> Repo.insert()
  end

  # Orders

  def get_order(id) do
    Repo.get(Order, id)
  end

  def get_order!(id) do
    Repo.get!(Order, id)
  end

  def get_order_with_preloads(id) do
    Order
    |> Repo.get(id)
    |> Repo.preload([:user, :company])
  end

  def create_order(attrs) do
    %Order{}
    |> Order.changeset(attrs)
    |> Repo.insert()
  end

  def update_order(%Order{} = order, attrs) do
    order
    |> Order.status_changeset(attrs)
    |> Repo.update()
  end

  def cancel_order(%Order{} = order) do
    if Order.open?(order) do
      update_order(order, %{status: "cancelled"})
    else
      {:error, :cannot_cancel}
    end
  end

  def list_user_orders(user_id, company_id \\ nil) do
    query = from(o in Order, where: o.user_id == ^user_id, order_by: [desc: o.inserted_at])
    query = if company_id, do: where(query, [o], o.company_id == ^company_id), else: query
    query |> preload(:company) |> Repo.all()
  end

  def list_open_user_orders(user_id, company_id) do
    from(o in Order,
      where: o.user_id == ^user_id,
      where: o.company_id == ^company_id,
      where: o.status in ["open", "partially_filled"],
      order_by: [desc: o.inserted_at]
    )
    |> Repo.all()
  end

  # Order Book queries

  def get_order_book(company_id) do
    bids = get_bids(company_id)
    asks = get_asks(company_id)
    %{bids: bids, asks: asks}
  end

  def get_bids(company_id) do
    from(o in Order,
      where: o.company_id == ^company_id,
      where: o.side == "buy",
      where: o.status in ["open", "partially_filled"],
      order_by: [desc: o.price, asc: o.inserted_at],
      select: %{
        id: o.id,
        price: o.price,
        quantity: o.remaining_quantity,
        user_id: o.user_id,
        inserted_at: o.inserted_at
      }
    )
    |> Repo.all()
  end

  def get_asks(company_id) do
    from(o in Order,
      where: o.company_id == ^company_id,
      where: o.side == "sell",
      where: o.status in ["open", "partially_filled"],
      order_by: [asc: o.price, asc: o.inserted_at],
      select: %{
        id: o.id,
        price: o.price,
        quantity: o.remaining_quantity,
        user_id: o.user_id,
        inserted_at: o.inserted_at
      }
    )
    |> Repo.all()
  end

  # Matching queries - get orders that can match with incoming order

  def get_matching_sells(company_id, max_price) do
    from(o in Order,
      where: o.company_id == ^company_id,
      where: o.side == "sell",
      where: o.status in ["open", "partially_filled"],
      where: o.price <= ^max_price,
      order_by: [asc: o.price, asc: o.inserted_at],
      lock: "FOR UPDATE"
    )
    |> Repo.all()
  end

  def get_matching_buys(company_id, min_price) do
    from(o in Order,
      where: o.company_id == ^company_id,
      where: o.side == "buy",
      where: o.status in ["open", "partially_filled"],
      where: o.price >= ^min_price,
      order_by: [desc: o.price, asc: o.inserted_at],
      lock: "FOR UPDATE"
    )
    |> Repo.all()
  end

  # Trades

  def create_trade(attrs) do
    %Trade{}
    |> Trade.changeset(attrs)
    |> Repo.insert()
  end

  def list_company_trades(company_id, limit \\ 50) do
    from(t in Trade,
      where: t.company_id == ^company_id,
      order_by: [desc: t.inserted_at],
      limit: ^limit,
      preload: [:buyer, :seller]
    )
    |> Repo.all()
  end

  def list_user_trades(user_id) do
    from(t in Trade,
      where: t.buyer_id == ^user_id or t.seller_id == ^user_id,
      order_by: [desc: t.inserted_at],
      preload: [:company, :buyer, :seller]
    )
    |> Repo.all()
  end

  # Expired orders

  def get_expired_orders do
    now = DateTime.utc_now()
    from(o in Order,
      where: o.status in ["open", "partially_filled"],
      where: not is_nil(o.expires_at),
      where: o.expires_at <= ^now
    )
    |> Repo.all()
  end

  def expire_order(%Order{} = order) do
    update_order(order, %{status: "expired"})
  end
end
