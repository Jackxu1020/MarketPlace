defmodule Backend.Accounts do
  @moduledoc """
  The Accounts context - manages users and their holdings.
  """

  import Ecto.Query
  alias Backend.Repo
  alias Backend.Accounts.{User, Holding}

  # Users

  def list_users do
    Repo.all(User)
  end

  def get_user(id) do
    Repo.get(User, id)
  end

  def get_user!(id) do
    Repo.get!(User, id)
  end

  def get_user_with_holdings(id) do
    User
    |> Repo.get(id)
    |> Repo.preload(holdings: :company)
  end

  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  # Cash Balance Operations

  def get_cash_balance(user_id) do
    case get_user(user_id) do
      nil -> {:error, :user_not_found}
      user -> {:ok, user.cash_balance}
    end
  end

  def update_cash_balance(user_id, amount) do
    from(u in User, where: u.id == ^user_id)
    |> Repo.update_all(inc: [cash_balance: amount])
  end

  def has_sufficient_funds?(user_id, amount) do
    case get_user(user_id) do
      nil -> false
      user -> Decimal.compare(user.cash_balance, amount) != :lt
    end
  end

  # Holdings

  def get_holding(user_id, company_id) do
    Repo.get_by(Holding, user_id: user_id, company_id: company_id)
  end

  def get_holding!(user_id, company_id) do
    Repo.get_by!(Holding, user_id: user_id, company_id: company_id)
  end

  def get_or_create_holding(user_id, company_id) do
    case get_holding(user_id, company_id) do
      nil ->
        %Holding{}
        |> Holding.changeset(%{user_id: user_id, company_id: company_id, quantity: 0})
        |> Repo.insert()
      holding ->
        {:ok, holding}
    end
  end

  def list_user_holdings(user_id) do
    Holding
    |> where([h], h.user_id == ^user_id)
    |> where([h], h.quantity > 0)
    |> preload(:company)
    |> Repo.all()
  end

  def get_holding_quantity(user_id, company_id) do
    case get_holding(user_id, company_id) do
      nil -> 0
      holding -> holding.quantity
    end
  end

  def has_sufficient_shares?(user_id, company_id, quantity) do
    get_holding_quantity(user_id, company_id) >= quantity
  end

  def update_holding_quantity(user_id, company_id, quantity_change) do
    case get_or_create_holding(user_id, company_id) do
      {:ok, holding} ->
        new_quantity = holding.quantity + quantity_change
        if new_quantity < 0 do
          {:error, :insufficient_shares}
        else
          holding
          |> Holding.changeset(%{quantity: new_quantity})
          |> Repo.update()
        end
      {:error, _} = error ->
        error
    end
  end

  # Direct update for use in transactions
  def increment_holding(user_id, company_id, amount) do
    case get_holding(user_id, company_id) do
      nil ->
        %Holding{}
        |> Holding.changeset(%{user_id: user_id, company_id: company_id, quantity: amount})
        |> Repo.insert()
      _holding ->
        from(h in Holding,
          where: h.user_id == ^user_id and h.company_id == ^company_id
        )
        |> Repo.update_all(inc: [quantity: amount])
        {:ok, :updated}
    end
  end

  def decrement_holding(user_id, company_id, amount) do
    from(h in Holding,
      where: h.user_id == ^user_id and h.company_id == ^company_id and h.quantity >= ^amount
    )
    |> Repo.update_all(inc: [quantity: -amount])
    |> case do
      {1, _} -> {:ok, :updated}
      {0, _} -> {:error, :insufficient_shares}
    end
  end
end
