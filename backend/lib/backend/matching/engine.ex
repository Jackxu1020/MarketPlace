defmodule Backend.Matching.Engine do
  @moduledoc """
  Order matching engine implementing price-time priority.

  Algorithm:
  - Buy orders match against sells with price <= buy price (lowest sell first, then earliest)
  - Sell orders match against buys with price >= sell price (highest buy first, then earliest)
  - Execution happens at the resting (maker) order's price
  - Supports partial fills
  - All operations within a single database transaction
  """

  alias Backend.Repo
  alias Backend.Accounts
  alias Backend.Marketplace
  alias Backend.Marketplace.Order
  alias Backend.Audit

  @doc """
  Process a new order: validate, insert, and attempt matching.
  Returns {:ok, order, trades} or {:error, reason}
  """
  def process_order(attrs) do
    Repo.transaction(fn ->
      with {:ok, order} <- validate_and_create_order(attrs),
           {:ok, order, trades} <- match_order(order) do
        # Broadcast updates
        broadcast_order_book_update(order.company_id)
        Enum.each(trades, &broadcast_trade/1)

        {order, trades}
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
    |> case do
      {:ok, {order, trades}} -> {:ok, order, trades}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Validate order params and create order if valid.
  """
  def validate_and_create_order(attrs) do
    side = attrs[:side] || attrs["side"]
    user_id = attrs[:user_id] || attrs["user_id"]
    company_id = attrs[:company_id] || attrs["company_id"]
    quantity = attrs[:quantity] || attrs["quantity"]
    price = attrs[:price] || attrs["price"]

    price = ensure_decimal(price)
    total_cost = Decimal.mult(price, Decimal.new(quantity))

    cond do
      side == "buy" and not Accounts.has_sufficient_funds?(user_id, total_cost) ->
        {:error, :insufficient_funds}

      side == "sell" and not Accounts.has_sufficient_shares?(user_id, company_id, quantity) ->
        {:error, :insufficient_shares}

      true ->
        case Marketplace.create_order(attrs) do
          {:ok, order} ->
            order = Repo.preload(order, [:user, :company])
            Audit.log("order_created", "order", order.id, user_id, %{
              side: order.side,
              price: Decimal.to_string(order.price),
              quantity: order.quantity,
              company_id: order.company_id
            })
            {:ok, order}

          {:error, changeset} ->
            {:error, changeset}
        end
    end
  end

  @doc """
  Attempt to match an order against the order book.
  Returns {:ok, updated_order, trades}
  """
  def match_order(%Order{} = order) do
    case order.side do
      "buy" -> match_buy_order(order)
      "sell" -> match_sell_order(order)
    end
  end

  defp match_buy_order(%Order{} = buy_order) do
    # Get all sell orders with price <= buy price, sorted by price ASC then time ASC
    matching_sells = Marketplace.get_matching_sells(buy_order.company_id, buy_order.price)
    execute_matches(buy_order, matching_sells, [])
  end

  defp match_sell_order(%Order{} = sell_order) do
    # Get all buy orders with price >= sell price, sorted by price DESC then time ASC
    matching_buys = Marketplace.get_matching_buys(sell_order.company_id, sell_order.price)
    execute_matches(sell_order, matching_buys, [])
  end

  defp execute_matches(%Order{remaining_quantity: 0} = order, _resting_orders, trades) do
    # Incoming order fully filled
    {:ok, order, Enum.reverse(trades)}
  end

  defp execute_matches(%Order{} = order, [], trades) do
    # No more matching orders
    {:ok, order, Enum.reverse(trades)}
  end

  defp execute_matches(%Order{} = incoming_order, [resting_order | rest], trades) do
    # Don't match orders from the same user
    if incoming_order.user_id == resting_order.user_id do
      execute_matches(incoming_order, rest, trades)
    else
      fill_quantity = min(incoming_order.remaining_quantity, resting_order.remaining_quantity)
      # Execute at resting order's price (maker price)
      execution_price = resting_order.price

      {buy_order, sell_order} =
        if incoming_order.side == "buy" do
          {incoming_order, resting_order}
        else
          {resting_order, incoming_order}
        end

      # Create trade
      {:ok, trade} = create_trade(buy_order, sell_order, execution_price, fill_quantity)

      # Update order quantities and statuses
      {:ok, updated_incoming} = update_order_after_fill(incoming_order, fill_quantity)
      {:ok, _updated_resting} = update_order_after_fill(resting_order, fill_quantity)

      # Update balances and holdings
      transfer_funds_and_shares(buy_order, sell_order, execution_price, fill_quantity)

      # Continue matching with remaining quantity
      execute_matches(updated_incoming, rest, [trade | trades])
    end
  end

  defp create_trade(buy_order, sell_order, price, quantity) do
    attrs = %{
      price: price,
      quantity: quantity,
      buy_order_id: buy_order.id,
      sell_order_id: sell_order.id,
      company_id: buy_order.company_id,
      buyer_id: buy_order.user_id,
      seller_id: sell_order.user_id
    }

    case Marketplace.create_trade(attrs) do
      {:ok, trade} ->
        trade = Repo.preload(trade, [:buyer, :seller])

        Audit.log("trade_executed", "trade", trade.id, nil, %{
          price: Decimal.to_string(price),
          quantity: quantity,
          buy_order_id: buy_order.id,
          sell_order_id: sell_order.id,
          buyer_id: buy_order.user_id,
          seller_id: sell_order.user_id
        })

        {:ok, trade}

      error ->
        error
    end
  end

  defp update_order_after_fill(%Order{} = order, fill_quantity) do
    new_remaining = order.remaining_quantity - fill_quantity

    new_status =
      cond do
        new_remaining == 0 -> "filled"
        new_remaining < order.quantity -> "partially_filled"
        true -> order.status
      end

    order
    |> Order.status_changeset(%{remaining_quantity: new_remaining, status: new_status})
    |> Repo.update()
    |> case do
      {:ok, updated_order} ->
        if new_status == "filled" do
          Audit.log("order_filled", "order", order.id, order.user_id, %{
            fill_quantity: fill_quantity,
            final_status: new_status
          })

          broadcast_order_filled(updated_order)
        end

        {:ok, updated_order}

      error ->
        error
    end
  end

  defp transfer_funds_and_shares(buy_order, sell_order, price, quantity) do
    total_cost = Decimal.mult(price, Decimal.new(quantity))

    # Buyer pays, seller receives
    Accounts.update_cash_balance(buy_order.user_id, Decimal.negate(total_cost))
    Accounts.update_cash_balance(sell_order.user_id, total_cost)

    # Seller transfers shares to buyer
    Accounts.decrement_holding(sell_order.user_id, sell_order.company_id, quantity)
    Accounts.increment_holding(buy_order.user_id, buy_order.company_id, quantity)
  end

  defp ensure_decimal(%Decimal{} = d), do: d
  defp ensure_decimal(n) when is_number(n), do: Decimal.new(n)
  defp ensure_decimal(s) when is_binary(s), do: Decimal.new(s)

  # Broadcasting helpers

  defp broadcast_order_book_update(company_id) do
    order_book = Marketplace.get_order_book(company_id)

    Phoenix.PubSub.broadcast(
      Backend.PubSub,
      "company:#{company_id}",
      {:order_book_update, order_book}
    )
  end

  defp broadcast_trade(trade) do
    Phoenix.PubSub.broadcast(
      Backend.PubSub,
      "company:#{trade.company_id}",
      {:new_trade, trade}
    )
  end

  defp broadcast_order_filled(order) do
    Phoenix.PubSub.broadcast(
      Backend.PubSub,
      "user:#{order.user_id}",
      {:order_filled, order}
    )
  end
end
