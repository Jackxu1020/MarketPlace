import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { api } from '../api/client';
import { useUser } from '../contexts/UserContext';
import type { Company } from '../types';

interface Props {
  company: Company;
}

export function MyOrders({ company }: Props) {
  const { currentUser } = useUser();
  const queryClient = useQueryClient();

  const { data, isLoading } = useQuery({
    queryKey: ['userOrders', currentUser?.id, company.id],
    queryFn: () => api.getUserOrders(currentUser!.id, company.id),
    enabled: currentUser !== null,
    refetchInterval: 5000, // Poll every 5 seconds for updates
  });

  const cancelMutation = useMutation({
    mutationFn: (orderId: number) => api.cancelOrder(orderId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['userOrders', currentUser?.id, company.id] });
    },
  });

  const orders = data?.data || [];

  const formatPrice = (price: string) => `$${parseFloat(price).toFixed(2)}`;

  if (!currentUser) {
    return (
      <div style={styles.container}>
        <h3 style={styles.title}>My Orders</h3>
        <div style={styles.empty}>Select a user to see orders</div>
      </div>
    );
  }

  return (
    <div style={styles.container}>
      <h3 style={styles.title}>My Orders</h3>
      {isLoading ? (
        <div style={styles.empty}>Loading...</div>
      ) : orders.length === 0 ? (
        <div style={styles.empty}>No open orders</div>
      ) : (
        <div style={styles.list}>
          {orders.map((order) => (
            <div key={order.id} style={styles.order}>
              <div style={styles.orderMain}>
                <span
                  style={{
                    ...styles.side,
                    color: order.side === 'buy' ? '#4ade80' : '#f87171',
                  }}
                >
                  {order.side.toUpperCase()}
                </span>
                <span style={styles.quantity}>
                  {order.remaining_quantity}/{order.quantity}
                </span>
                <span style={styles.at}>@</span>
                <span style={styles.price}>{formatPrice(order.price)}</span>
              </div>
              <div style={styles.orderActions}>
                <span style={styles.status}>{order.status.replace('_', ' ')}</span>
                <button
                  style={styles.cancelButton}
                  onClick={() => cancelMutation.mutate(order.id)}
                  disabled={cancelMutation.isPending}
                >
                  Cancel
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

const styles: Record<string, React.CSSProperties> = {
  container: {
    backgroundColor: '#1a1a2e',
    borderRadius: '8px',
    padding: '16px',
    border: '1px solid #333',
  },
  title: {
    margin: '0 0 16px 0',
    fontSize: '16px',
    color: '#fff',
  },
  empty: {
    color: '#666',
    fontSize: '14px',
    padding: '16px 0',
    textAlign: 'center',
  },
  list: {
    display: 'flex',
    flexDirection: 'column',
    gap: '8px',
  },
  order: {
    padding: '12px',
    backgroundColor: '#2a2a3e',
    borderRadius: '4px',
  },
  orderMain: {
    display: 'flex',
    alignItems: 'center',
    gap: '8px',
    marginBottom: '8px',
  },
  side: {
    fontSize: '12px',
    fontWeight: 'bold',
  },
  quantity: {
    fontSize: '14px',
    color: '#fff',
  },
  at: {
    color: '#666',
  },
  price: {
    fontSize: '14px',
    color: '#60a5fa',
  },
  orderActions: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  status: {
    fontSize: '12px',
    color: '#888',
    textTransform: 'capitalize',
  },
  cancelButton: {
    padding: '4px 12px',
    fontSize: '12px',
    borderRadius: '4px',
    border: '1px solid #f87171',
    backgroundColor: 'transparent',
    color: '#f87171',
    cursor: 'pointer',
  },
};
