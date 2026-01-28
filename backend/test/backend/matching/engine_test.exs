defmodule Backend.Matching.EngineTest do
  use Backend.DataCase, async: false

  alias Backend.Matching.Engine
  alias Backend.Accounts
  alias Backend.Marketplace

  setup do
    # Create test company
    {:ok, company} = Marketplace.create_company(%{
      name: "Test Company",
      ticker: "TEST",
      sector: "Technology",
      valuation: Decimal.new("1000000000"),
      total_shares: 10_000_000
    })

    # Create buyer with cash
    {:ok, buyer} = Accounts.create_user(%{
      name: "Buyer",
      email: "buyer@test.com",
      cash_balance: Decimal.new("100000")
    })

    # Create seller with shares
    {:ok, seller} = Accounts.create_user(%{
      name: "Seller",
      email: "seller@test.com",
      cash_balance: Decimal.new("10000")
    })

    # Give seller some shares
    {:ok, _} = Accounts.increment_holding(seller.id, company.id, 1000)

    %{company: company, buyer: buyer, seller: seller}
  end

  describe "order validation" do
    test "rejects buy order when insufficient funds", %{company: company, buyer: buyer} do
      # Try to buy more than buyer can afford
      result = Engine.process_order(%{
        side: "buy",
        price: Decimal.new("200"),  # 200 * 1000 = 200,000 > 100,000 balance
        quantity: 1000,
        user_id: buyer.id,
        company_id: company.id
      })

      assert {:error, :insufficient_funds} = result
    end

    test "rejects sell order when insufficient shares", %{company: company, seller: seller} do
      # Try to sell more shares than seller owns
      result = Engine.process_order(%{
        side: "sell",
        price: Decimal.new("50"),
        quantity: 2000,  # seller only has 1000
        user_id: seller.id,
        company_id: company.id
      })

      assert {:error, :insufficient_shares} = result
    end

    test "accepts valid buy order", %{company: company, buyer: buyer} do
      result = Engine.process_order(%{
        side: "buy",
        price: Decimal.new("50"),
        quantity: 100,
        user_id: buyer.id,
        company_id: company.id
      })

      assert {:ok, order, []} = result
      assert order.side == "buy"
      assert order.status == "open"
      assert order.remaining_quantity == 100
    end

    test "accepts valid sell order", %{company: company, seller: seller} do
      result = Engine.process_order(%{
        side: "sell",
        price: Decimal.new("50"),
        quantity: 100,
        user_id: seller.id,
        company_id: company.id
      })

      assert {:ok, order, []} = result
      assert order.side == "sell"
      assert order.status == "open"
      assert order.remaining_quantity == 100
    end
  end

  describe "full fill matching" do
    test "buy order fully fills against existing sell at same price", %{company: company, buyer: buyer, seller: seller} do
      # Create sell order first
      {:ok, sell_order, []} = Engine.process_order(%{
        side: "sell",
        price: Decimal.new("50"),
        quantity: 100,
        user_id: seller.id,
        company_id: company.id
      })

      assert sell_order.status == "open"

      # Create matching buy order
      {:ok, buy_order, trades} = Engine.process_order(%{
        side: "buy",
        price: Decimal.new("50"),
        quantity: 100,
        user_id: buyer.id,
        company_id: company.id
      })

      assert buy_order.status == "filled"
      assert buy_order.remaining_quantity == 0
      assert length(trades) == 1

      [trade] = trades
      assert trade.quantity == 100
      assert Decimal.equal?(trade.price, Decimal.new("50"))
      assert trade.buyer_id == buyer.id
      assert trade.seller_id == seller.id

      # Verify sell order is also filled
      updated_sell = Marketplace.get_order!(sell_order.id)
      assert updated_sell.status == "filled"
      assert updated_sell.remaining_quantity == 0

      # Verify balance transfers
      updated_buyer = Accounts.get_user!(buyer.id)
      updated_seller = Accounts.get_user!(seller.id)

      # Buyer spent 50 * 100 = 5000
      assert Decimal.equal?(updated_buyer.cash_balance, Decimal.new("95000"))
      # Seller received 5000
      assert Decimal.equal?(updated_seller.cash_balance, Decimal.new("15000"))

      # Verify holdings
      assert Accounts.get_holding_quantity(buyer.id, company.id) == 100
      assert Accounts.get_holding_quantity(seller.id, company.id) == 900
    end

    test "sell order fully fills against existing buy", %{company: company, buyer: buyer, seller: seller} do
      # Create buy order first
      {:ok, buy_order, []} = Engine.process_order(%{
        side: "buy",
        price: Decimal.new("60"),
        quantity: 100,
        user_id: buyer.id,
        company_id: company.id
      })

      assert buy_order.status == "open"

      # Create matching sell order at lower price
      {:ok, sell_order, trades} = Engine.process_order(%{
        side: "sell",
        price: Decimal.new("55"),
        quantity: 100,
        user_id: seller.id,
        company_id: company.id
      })

      assert sell_order.status == "filled"
      assert length(trades) == 1

      [trade] = trades
      # Execute at resting (buy) order's price
      assert Decimal.equal?(trade.price, Decimal.new("60"))
    end
  end

  describe "partial fill matching" do
    test "buy order partially fills when sell quantity is less", %{company: company, buyer: buyer, seller: seller} do
      # Sell 50 shares
      {:ok, _sell_order, []} = Engine.process_order(%{
        side: "sell",
        price: Decimal.new("50"),
        quantity: 50,
        user_id: seller.id,
        company_id: company.id
      })

      # Try to buy 100 shares
      {:ok, buy_order, trades} = Engine.process_order(%{
        side: "buy",
        price: Decimal.new("50"),
        quantity: 100,
        user_id: buyer.id,
        company_id: company.id
      })

      assert buy_order.status == "partially_filled"
      assert buy_order.remaining_quantity == 50
      assert length(trades) == 1

      [trade] = trades
      assert trade.quantity == 50
    end

    test "buy order fills multiple sell orders", %{company: company, buyer: buyer, seller: seller} do
      # Create second seller
      {:ok, seller2} = Accounts.create_user(%{
        name: "Seller2",
        email: "seller2@test.com",
        cash_balance: Decimal.new("5000")
      })
      {:ok, _} = Accounts.increment_holding(seller2.id, company.id, 500)

      # Create two sell orders
      {:ok, _sell1, []} = Engine.process_order(%{
        side: "sell",
        price: Decimal.new("50"),
        quantity: 60,
        user_id: seller.id,
        company_id: company.id
      })

      {:ok, _sell2, []} = Engine.process_order(%{
        side: "sell",
        price: Decimal.new("50"),
        quantity: 40,
        user_id: seller2.id,
        company_id: company.id
      })

      # Buy 100 shares - should match both sells
      {:ok, buy_order, trades} = Engine.process_order(%{
        side: "buy",
        price: Decimal.new("50"),
        quantity: 100,
        user_id: buyer.id,
        company_id: company.id
      })

      assert buy_order.status == "filled"
      assert buy_order.remaining_quantity == 0
      assert length(trades) == 2

      quantities = Enum.map(trades, & &1.quantity) |> Enum.sort()
      assert quantities == [40, 60]
    end
  end

  describe "no match scenarios" do
    test "buy order doesn't match when sell price is higher", %{company: company, buyer: buyer, seller: seller} do
      # Sell at 60
      {:ok, _sell_order, []} = Engine.process_order(%{
        side: "sell",
        price: Decimal.new("60"),
        quantity: 100,
        user_id: seller.id,
        company_id: company.id
      })

      # Try to buy at 50 - no match
      {:ok, buy_order, trades} = Engine.process_order(%{
        side: "buy",
        price: Decimal.new("50"),
        quantity: 100,
        user_id: buyer.id,
        company_id: company.id
      })

      assert buy_order.status == "open"
      assert buy_order.remaining_quantity == 100
      assert trades == []
    end

    test "sell order doesn't match when buy price is lower", %{company: company, buyer: buyer, seller: seller} do
      # Buy at 40
      {:ok, _buy_order, []} = Engine.process_order(%{
        side: "buy",
        price: Decimal.new("40"),
        quantity: 100,
        user_id: buyer.id,
        company_id: company.id
      })

      # Sell at 50 - no match
      {:ok, sell_order, trades} = Engine.process_order(%{
        side: "sell",
        price: Decimal.new("50"),
        quantity: 100,
        user_id: seller.id,
        company_id: company.id
      })

      assert sell_order.status == "open"
      assert sell_order.remaining_quantity == 100
      assert trades == []
    end
  end

  describe "price priority" do
    test "buy order matches lowest priced sell first", %{company: company, buyer: buyer, seller: seller} do
      # Create second seller
      {:ok, seller2} = Accounts.create_user(%{
        name: "Seller2",
        email: "seller2@test.com",
        cash_balance: Decimal.new("5000")
      })
      {:ok, _} = Accounts.increment_holding(seller2.id, company.id, 500)

      # Higher priced sell first
      {:ok, sell_high, []} = Engine.process_order(%{
        side: "sell",
        price: Decimal.new("55"),
        quantity: 100,
        user_id: seller.id,
        company_id: company.id
      })

      # Lower priced sell second
      {:ok, sell_low, []} = Engine.process_order(%{
        side: "sell",
        price: Decimal.new("50"),
        quantity: 100,
        user_id: seller2.id,
        company_id: company.id
      })

      # Buy should match lower priced sell first
      {:ok, buy_order, trades} = Engine.process_order(%{
        side: "buy",
        price: Decimal.new("55"),
        quantity: 100,
        user_id: buyer.id,
        company_id: company.id
      })

      assert buy_order.status == "filled"
      assert length(trades) == 1

      [trade] = trades
      # Should execute at seller2's price (50)
      assert Decimal.equal?(trade.price, Decimal.new("50"))
      assert trade.seller_id == seller2.id

      # Lower sell should be filled, higher should remain open
      assert Marketplace.get_order!(sell_low.id).status == "filled"
      assert Marketplace.get_order!(sell_high.id).status == "open"
    end

    test "sell order matches highest priced buy first", %{company: company, buyer: buyer, seller: seller} do
      # Create second buyer
      {:ok, buyer2} = Accounts.create_user(%{
        name: "Buyer2",
        email: "buyer2@test.com",
        cash_balance: Decimal.new("100000")
      })

      # Lower priced buy first
      {:ok, buy_low, []} = Engine.process_order(%{
        side: "buy",
        price: Decimal.new("45"),
        quantity: 100,
        user_id: buyer.id,
        company_id: company.id
      })

      # Higher priced buy second
      {:ok, buy_high, []} = Engine.process_order(%{
        side: "buy",
        price: Decimal.new("50"),
        quantity: 100,
        user_id: buyer2.id,
        company_id: company.id
      })

      # Sell should match higher priced buy first
      {:ok, sell_order, trades} = Engine.process_order(%{
        side: "sell",
        price: Decimal.new("45"),
        quantity: 100,
        user_id: seller.id,
        company_id: company.id
      })

      assert sell_order.status == "filled"
      assert length(trades) == 1

      [trade] = trades
      # Should execute at buyer2's price (50)
      assert Decimal.equal?(trade.price, Decimal.new("50"))
      assert trade.buyer_id == buyer2.id

      # Higher buy should be filled, lower should remain open
      assert Marketplace.get_order!(buy_high.id).status == "filled"
      assert Marketplace.get_order!(buy_low.id).status == "open"
    end
  end

  describe "time priority" do
    test "at same price, earlier order matches first", %{company: company, buyer: buyer, seller: seller} do
      # Create second seller
      {:ok, seller2} = Accounts.create_user(%{
        name: "Seller2",
        email: "seller2@test.com",
        cash_balance: Decimal.new("5000")
      })
      {:ok, _} = Accounts.increment_holding(seller2.id, company.id, 500)

      # First sell
      {:ok, sell_first, []} = Engine.process_order(%{
        side: "sell",
        price: Decimal.new("50"),
        quantity: 100,
        user_id: seller.id,
        company_id: company.id
      })

      # Small delay to ensure different timestamps
      Process.sleep(10)

      # Second sell at same price
      {:ok, sell_second, []} = Engine.process_order(%{
        side: "sell",
        price: Decimal.new("50"),
        quantity: 100,
        user_id: seller2.id,
        company_id: company.id
      })

      # Buy should match earlier sell first
      {:ok, buy_order, trades} = Engine.process_order(%{
        side: "buy",
        price: Decimal.new("50"),
        quantity: 100,
        user_id: buyer.id,
        company_id: company.id
      })

      assert buy_order.status == "filled"
      assert length(trades) == 1

      [trade] = trades
      assert trade.seller_id == seller.id

      # First sell should be filled, second should remain open
      assert Marketplace.get_order!(sell_first.id).status == "filled"
      assert Marketplace.get_order!(sell_second.id).status == "open"
    end
  end

  describe "self-matching prevention" do
    test "user cannot match against own orders", %{company: company, seller: seller} do
      # Give seller more cash
      Accounts.update_cash_balance(seller.id, Decimal.new("50000"))

      # Seller creates sell order
      {:ok, sell_order, []} = Engine.process_order(%{
        side: "sell",
        price: Decimal.new("50"),
        quantity: 50,
        user_id: seller.id,
        company_id: company.id
      })

      # Seller tries to buy their own shares - should not match
      {:ok, buy_order, trades} = Engine.process_order(%{
        side: "buy",
        price: Decimal.new("50"),
        quantity: 50,
        user_id: seller.id,
        company_id: company.id
      })

      assert buy_order.status == "open"
      assert trades == []
      assert Marketplace.get_order!(sell_order.id).status == "open"
    end
  end
end
