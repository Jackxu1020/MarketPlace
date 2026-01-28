defmodule BackendWeb.Api.V1.TradeController do
  use BackendWeb, :controller

  alias Backend.Marketplace

  def index(conn, %{"company_id" => company_id}) do
    trades = Marketplace.list_company_trades(company_id)
    json(conn, %{data: Enum.map(trades, &trade_json/1)})
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
      company_id: trade.company_id,
      inserted_at: trade.inserted_at
    }
  end
end
