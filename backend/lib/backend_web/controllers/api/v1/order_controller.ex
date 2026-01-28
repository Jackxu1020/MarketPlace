defmodule BackendWeb.Api.V1.OrderController do
  use BackendWeb, :controller

  alias Backend.Marketplace
  alias Backend.Matching.Engine
  alias Backend.Audit

  def index(conn, %{"company_id" => company_id}) do
    order_book = Marketplace.get_order_book(company_id)

    json(conn, %{
      data: %{
        bids: format_orders(order_book.bids),
        asks: format_orders(order_book.asks)
      }
    })
  end

  def create(conn, %{"company_id" => company_id, "order" => order_params}) do
    attrs = %{
      company_id: String.to_integer(company_id),
      user_id: order_params["user_id"],
      side: order_params["side"],
      price: order_params["price"],
      quantity: order_params["quantity"],
      expires_at: parse_expiry(order_params["expires_at"])
    }

    case Engine.process_order(attrs) do
      {:ok, order, trades} ->
        conn
        |> put_status(:created)
        |> json(%{
          data: %{
            order: order_json(order),
            trades: Enum.map(trades, &trade_json/1)
          }
        })

      {:error, :insufficient_funds} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Insufficient funds"})

      {:error, :insufficient_shares} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Insufficient shares"})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: format_changeset_errors(changeset)})
    end
  end

  def delete(conn, %{"id" => id}) do
    case Marketplace.get_order(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Order not found"})

      order ->
        case Marketplace.cancel_order(order) do
          {:ok, cancelled_order} ->
            Audit.log("order_cancelled", "order", order.id, order.user_id, %{})

            # Broadcast cancellation
            Phoenix.PubSub.broadcast(
              Backend.PubSub,
              "company:#{order.company_id}",
              {:order_book_update, Marketplace.get_order_book(order.company_id)}
            )

            Phoenix.PubSub.broadcast(
              Backend.PubSub,
              "user:#{order.user_id}",
              {:order_cancelled, cancelled_order}
            )

            json(conn, %{data: order_json(cancelled_order)})

          {:error, :cannot_cancel} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{error: "Cannot cancel order - already filled or cancelled"})
        end
    end
  end

  def user_orders(conn, %{"user_id" => user_id, "company_id" => company_id}) do
    orders = Marketplace.list_open_user_orders(user_id, company_id)
    json(conn, %{data: Enum.map(orders, &order_json/1)})
  end

  defp format_orders(orders) do
    Enum.map(orders, fn o ->
      %{
        id: o.id,
        price: Decimal.to_string(o.price),
        quantity: o.quantity,
        user_id: o.user_id
      }
    end)
  end

  defp order_json(order) do
    %{
      id: order.id,
      side: order.side,
      price: Decimal.to_string(order.price),
      quantity: order.quantity,
      remaining_quantity: order.remaining_quantity,
      status: order.status,
      user_id: order.user_id,
      company_id: order.company_id,
      expires_at: order.expires_at,
      inserted_at: order.inserted_at
    }
  end

  defp trade_json(trade) do
    %{
      id: trade.id,
      price: Decimal.to_string(trade.price),
      quantity: trade.quantity,
      buyer_id: trade.buyer_id,
      seller_id: trade.seller_id,
      buyer_name: trade.buyer && trade.buyer.name,
      seller_name: trade.seller && trade.seller.name,
      inserted_at: trade.inserted_at
    }
  end

  defp parse_expiry(nil), do: nil
  defp parse_expiry(""), do: nil
  defp parse_expiry(expiry) when is_binary(expiry) do
    case DateTime.from_iso8601(expiry) do
      {:ok, dt, _} -> dt
      _ -> nil
    end
  end
  defp parse_expiry(_), do: nil

  defp format_changeset_errors(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
  defp format_changeset_errors(error), do: inspect(error)
end
