defmodule BackendWeb.Router do
  use BackendWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api/v1", BackendWeb.Api.V1 do
    pipe_through :api

    resources "/users", UserController, only: [:index, :show]
    resources "/companies", CompanyController, only: [:index, :show]

    # Nested under companies
    get "/companies/:company_id/orders", OrderController, :index
    post "/companies/:company_id/orders", OrderController, :create
    get "/companies/:company_id/trades", TradeController, :index

    # User's orders for a company
    get "/users/:user_id/companies/:company_id/orders", OrderController, :user_orders

    # Cancel order
    delete "/orders/:id", OrderController, :delete
  end
end
