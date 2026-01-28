# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs

alias Backend.Repo
alias Backend.Accounts.{User, Holding}
alias Backend.Marketplace.Company

# Clear existing data
Repo.delete_all(Holding)
Repo.delete_all(User)
Repo.delete_all(Company)

# Create users with cash balances
users = [
  %{name: "Alice Chen", email: "alice@example.com", cash_balance: Decimal.new("500000.00")},
  %{name: "Bob Smith", email: "bob@example.com", cash_balance: Decimal.new("750000.00")},
  %{name: "Carol Davis", email: "carol@example.com", cash_balance: Decimal.new("1000000.00")},
  %{name: "David Lee", email: "david@example.com", cash_balance: Decimal.new("250000.00")},
  %{name: "Emma Wilson", email: "emma@example.com", cash_balance: Decimal.new("600000.00")},
  %{name: "Frank Johnson", email: "frank@example.com", cash_balance: Decimal.new("400000.00")},
  %{name: "Grace Kim", email: "grace@example.com", cash_balance: Decimal.new("800000.00")},
  %{name: "Henry Brown", email: "henry@example.com", cash_balance: Decimal.new("350000.00")}
]

created_users = Enum.map(users, fn attrs ->
  %User{}
  |> User.changeset(attrs)
  |> Repo.insert!()
end)

IO.puts("Created #{length(created_users)} users")

# Create pre-IPO companies
companies = [
  %{
    name: "SpaceX",
    ticker: "SPACEX",
    description: "Space exploration and rocket manufacturing company",
    sector: "Aerospace",
    valuation: Decimal.new("150000000000.00"),
    total_shares: 1_000_000_000
  },
  %{
    name: "Stripe",
    ticker: "STRIPE",
    description: "Online payment processing platform",
    sector: "Fintech",
    valuation: Decimal.new("50000000000.00"),
    total_shares: 500_000_000
  },
  %{
    name: "Databricks",
    ticker: "DBRICKS",
    description: "Unified data analytics platform",
    sector: "Enterprise Software",
    valuation: Decimal.new("43000000000.00"),
    total_shares: 400_000_000
  },
  %{
    name: "Discord",
    ticker: "DISCRD",
    description: "Voice, video and text communication platform",
    sector: "Social Media",
    valuation: Decimal.new("15000000000.00"),
    total_shares: 300_000_000
  },
  %{
    name: "Canva",
    ticker: "CANVA",
    description: "Online design and publishing tool",
    sector: "Design Software",
    valuation: Decimal.new("26000000000.00"),
    total_shares: 350_000_000
  },
  %{
    name: "Plaid",
    ticker: "PLAID",
    description: "Financial data connectivity platform",
    sector: "Fintech",
    valuation: Decimal.new("13000000000.00"),
    total_shares: 250_000_000
  },
  %{
    name: "Notion",
    ticker: "NOTION",
    description: "All-in-one workspace for notes and collaboration",
    sector: "Productivity",
    valuation: Decimal.new("10000000000.00"),
    total_shares: 200_000_000
  },
  %{
    name: "Figma",
    ticker: "FIGMA",
    description: "Collaborative interface design tool",
    sector: "Design Software",
    valuation: Decimal.new("20000000000.00"),
    total_shares: 300_000_000
  }
]

created_companies = Enum.map(companies, fn attrs ->
  %Company{}
  |> Company.changeset(attrs)
  |> Repo.insert!()
end)

IO.puts("Created #{length(created_companies)} companies")

# Distribute holdings to users
# Each user gets shares in 3-5 random companies
holdings_data = [
  # Alice has SpaceX, Stripe, Databricks
  {0, 0, 5000},   # Alice - SpaceX
  {0, 1, 10000},  # Alice - Stripe
  {0, 2, 8000},   # Alice - Databricks

  # Bob has Stripe, Discord, Canva, Plaid
  {1, 1, 15000},  # Bob - Stripe
  {1, 3, 20000},  # Bob - Discord
  {1, 4, 12000},  # Bob - Canva
  {1, 5, 8000},   # Bob - Plaid

  # Carol has all companies (big investor)
  {2, 0, 10000},  # Carol - SpaceX
  {2, 1, 20000},  # Carol - Stripe
  {2, 2, 15000},  # Carol - Databricks
  {2, 3, 25000},  # Carol - Discord
  {2, 4, 18000},  # Carol - Canva
  {2, 5, 12000},  # Carol - Plaid
  {2, 6, 30000},  # Carol - Notion
  {2, 7, 22000},  # Carol - Figma

  # David has Discord, Notion, Figma
  {3, 3, 8000},   # David - Discord
  {3, 6, 15000},  # David - Notion
  {3, 7, 10000},  # David - Figma

  # Emma has SpaceX, Databricks, Canva, Notion
  {4, 0, 3000},   # Emma - SpaceX
  {4, 2, 12000},  # Emma - Databricks
  {4, 4, 20000},  # Emma - Canva
  {4, 6, 25000},  # Emma - Notion

  # Frank has Stripe, Plaid, Figma
  {5, 1, 8000},   # Frank - Stripe
  {5, 5, 15000},  # Frank - Plaid
  {5, 7, 18000},  # Frank - Figma

  # Grace has SpaceX, Discord, Notion, Figma
  {6, 0, 7000},   # Grace - SpaceX
  {6, 3, 30000},  # Grace - Discord
  {6, 6, 20000},  # Grace - Notion
  {6, 7, 15000},  # Grace - Figma

  # Henry has Databricks, Canva, Plaid
  {7, 2, 10000},  # Henry - Databricks
  {7, 4, 15000},  # Henry - Canva
  {7, 5, 20000}   # Henry - Plaid
]

holdings_count = Enum.count(holdings_data, fn {user_idx, company_idx, quantity} ->
  user = Enum.at(created_users, user_idx)
  company = Enum.at(created_companies, company_idx)

  %Holding{}
  |> Holding.changeset(%{user_id: user.id, company_id: company.id, quantity: quantity})
  |> Repo.insert!()

  true
end)

IO.puts("Created #{holdings_count} holdings")

IO.puts("\nSeed completed successfully!")
IO.puts("Users can now trade shares in pre-IPO companies.")
