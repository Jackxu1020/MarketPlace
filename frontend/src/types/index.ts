export interface User {
  id: number;
  name: string;
  email: string;
  cash_balance: string;
  holdings?: Holding[];
}

export interface Holding {
  company_id: number;
  company_name: string;
  company_ticker: string;
  quantity: number;
}

export interface Company {
  id: number;
  name: string;
  ticker: string;
  description: string;
  sector: string;
  valuation: string;
  total_shares: number;
}

export interface Order {
  id: number;
  side: 'buy' | 'sell';
  price: string;
  quantity: number;
  remaining_quantity: number;
  status: 'open' | 'partially_filled' | 'filled' | 'cancelled' | 'expired';
  user_id: number;
  company_id: number;
  expires_at: string | null;
  inserted_at: string;
}

export interface OrderBookEntry {
  id: number;
  price: string;
  quantity: number;
  user_id: number;
}

export interface OrderBook {
  bids: OrderBookEntry[];
  asks: OrderBookEntry[];
}

export interface Trade {
  id: number;
  price: string;
  quantity: number;
  buyer_id: number;
  seller_id: number;
  buyer_name: string;
  seller_name: string;
  company_id: number;
  inserted_at: string;
}

export interface CreateOrderParams {
  side: 'buy' | 'sell';
  price: string;
  quantity: number;
  user_id: number;
  expires_at?: string;
}
