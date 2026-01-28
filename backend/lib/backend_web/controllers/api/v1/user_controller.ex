defmodule BackendWeb.Api.V1.UserController do
  use BackendWeb, :controller

  alias Backend.Accounts

  def index(conn, _params) do
    users = Accounts.list_users()
    json(conn, %{data: Enum.map(users, &user_json/1)})
  end

  def show(conn, %{"id" => id}) do
    case Accounts.get_user_with_holdings(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "User not found"})

      user ->
        json(conn, %{data: user_with_holdings_json(user)})
    end
  end

  defp user_json(user) do
    %{
      id: user.id,
      name: user.name,
      email: user.email,
      cash_balance: Decimal.to_string(user.cash_balance)
    }
  end

  defp user_with_holdings_json(user) do
    %{
      id: user.id,
      name: user.name,
      email: user.email,
      cash_balance: Decimal.to_string(user.cash_balance),
      holdings: Enum.map(user.holdings, fn h ->
        %{
          company_id: h.company_id,
          company_name: h.company.name,
          company_ticker: h.company.ticker,
          quantity: h.quantity
        }
      end)
    }
  end
end
