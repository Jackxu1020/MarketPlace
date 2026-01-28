defmodule BackendWeb.CompanyChannel do
  use Phoenix.Channel

  alias Backend.Marketplace

  @impl true
  def join("company:" <> company_id, _params, socket) do
    # Subscribe to PubSub for this company
    Phoenix.PubSub.subscribe(Backend.PubSub, "company:#{company_id}")

    # Send initial order book
    order_book = Marketplace.get_order_book(company_id)
    trades = Marketplace.list_company_trades(company_id, 20)

    {:ok, %{
      order_book: format_order_book(order_book),
      recent_trades: Enum.map(trades, &format_trade/1)
    }, assign(socket, :company_id, company_id)}
  end

  @impl true
  def handle_info({:order_book_update, order_book}, socket) do
    push(socket, "order_book_update", format_order_book(order_book))
    {:noreply, socket}
  end

  @impl true
  def handle_info({:new_trade, trade}, socket) do
    push(socket, "new_trade", format_trade(trade))
    {:noreply, socket}
  end

  defp format_order_book(order_book) do
    %{
      bids: Enum.map(order_book.bids, &format_order/1),
      asks: Enum.map(order_book.asks, &format_order/1)
    }
  end

  defp format_order(order) do
    %{
      id: order.id,
      price: Decimal.to_string(order.price),
      quantity: order.quantity,
      user_id: order.user_id
    }
  end

  defp format_trade(trade) do
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
end
