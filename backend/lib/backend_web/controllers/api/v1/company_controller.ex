defmodule BackendWeb.Api.V1.CompanyController do
  use BackendWeb, :controller

  alias Backend.Marketplace

  def index(conn, _params) do
    companies = Marketplace.list_companies()
    json(conn, %{data: Enum.map(companies, &company_json/1)})
  end

  def show(conn, %{"id" => id}) do
    case Marketplace.get_company(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Company not found"})

      company ->
        json(conn, %{data: company_json(company)})
    end
  end

  defp company_json(company) do
    %{
      id: company.id,
      name: company.name,
      ticker: company.ticker,
      description: company.description,
      sector: company.sector,
      valuation: Decimal.to_string(company.valuation),
      total_shares: company.total_shares
    }
  end
end
