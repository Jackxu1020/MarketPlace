const API_BASE = 'http://localhost:4000/api/v1';

async function fetchJson<T>(url: string, options?: RequestInit): Promise<T> {
  const response = await fetch(`${API_BASE}${url}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...options?.headers,
    },
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({ error: 'Unknown error' }));
    throw new Error(error.error || `HTTP ${response.status}`);
  }

  return response.json();
}

export const api = {
  // Users
  getUsers: () => fetchJson<{ data: import('../types').User[] }>('/users'),
  getUser: (id: number) => fetchJson<{ data: import('../types').User }>(`/users/${id}`),

  // Companies
  getCompanies: () => fetchJson<{ data: import('../types').Company[] }>('/companies'),
  getCompany: (id: number) => fetchJson<{ data: import('../types').Company }>(`/companies/${id}`),

  // Orders
  getOrderBook: (companyId: number) =>
    fetchJson<{ data: import('../types').OrderBook }>(`/companies/${companyId}/orders`),

  createOrder: (companyId: number, order: import('../types').CreateOrderParams) =>
    fetchJson<{ data: { order: import('../types').Order; trades: import('../types').Trade[] } }>(
      `/companies/${companyId}/orders`,
      {
        method: 'POST',
        body: JSON.stringify({ order }),
      }
    ),

  cancelOrder: (orderId: number) =>
    fetchJson<{ data: import('../types').Order }>(`/orders/${orderId}`, {
      method: 'DELETE',
    }),

  getUserOrders: (userId: number, companyId: number) =>
    fetchJson<{ data: import('../types').Order[] }>(
      `/users/${userId}/companies/${companyId}/orders`
    ),

  // Trades
  getTrades: (companyId: number) =>
    fetchJson<{ data: import('../types').Trade[] }>(`/companies/${companyId}/trades`),
};
