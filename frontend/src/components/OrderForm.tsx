import { useState } from 'react';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { api } from '../api/client';
import { useUser } from '../contexts/UserContext';
import type { Company } from '../types';

interface Props {
  company: Company;
}

export function OrderForm({ company }: Props) {
  const { currentUser } = useUser();
  const queryClient = useQueryClient();

  const [side, setSide] = useState<'buy' | 'sell'>('buy');
  const [price, setPrice] = useState('');
  const [quantity, setQuantity] = useState('');
  const [error, setError] = useState<string | null>(null);

  const mutation = useMutation({
    mutationFn: () =>
      api.createOrder(company.id, {
        side,
        price,
        quantity: parseInt(quantity, 10),
        user_id: currentUser!.id,
      }),
    onSuccess: (data) => {
      setPrice('');
      setQuantity('');
      setError(null);
      // Refresh user data for updated balance
      queryClient.invalidateQueries({ queryKey: ['user', currentUser?.id] });
      // Show success message if trades occurred
      if (data.data.trades.length > 0) {
        const totalFilled = data.data.trades.reduce((sum, t) => sum + t.quantity, 0);
        console.log(`Order matched! ${totalFilled} shares traded.`);
      }
    },
    onError: (err: Error) => {
      setError(err.message);
    },
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!currentUser) {
      setError('Please select a user first');
      return;
    }
    if (!price || !quantity) {
      setError('Please fill in all fields');
      return;
    }
    setError(null);
    mutation.mutate();
  };

  const userHolding = currentUser?.holdings?.find((h) => h.company_id === company.id);

  return (
    <div style={styles.container}>
      <h3 style={styles.title}>Place Order</h3>

      {currentUser && userHolding && (
        <div style={styles.position}>
          Your Position: {userHolding.quantity.toLocaleString()} shares
        </div>
      )}

      <div style={styles.tabs}>
        <button
          style={{
            ...styles.tab,
            ...(side === 'buy' ? styles.tabActiveBuy : {}),
          }}
          onClick={() => setSide('buy')}
        >
          Buy
        </button>
        <button
          style={{
            ...styles.tab,
            ...(side === 'sell' ? styles.tabActiveSell : {}),
          }}
          onClick={() => setSide('sell')}
        >
          Sell
        </button>
      </div>

      <form onSubmit={handleSubmit} style={styles.form}>
        <div style={styles.field}>
          <label style={styles.label}>Price ($)</label>
          <input
            type="number"
            step="0.01"
            min="0.01"
            value={price}
            onChange={(e) => setPrice(e.target.value)}
            style={styles.input}
            placeholder="0.00"
          />
        </div>

        <div style={styles.field}>
          <label style={styles.label}>Quantity</label>
          <input
            type="number"
            min="1"
            value={quantity}
            onChange={(e) => setQuantity(e.target.value)}
            style={styles.input}
            placeholder="0"
          />
        </div>

        {price && quantity && (
          <div style={styles.total}>
            Total: ${(parseFloat(price) * parseInt(quantity || '0', 10)).toFixed(2)}
          </div>
        )}

        {error && <div style={styles.error}>{error}</div>}

        <button
          type="submit"
          style={{
            ...styles.button,
            backgroundColor: side === 'buy' ? '#4ade80' : '#f87171',
          }}
          disabled={!currentUser || mutation.isPending}
        >
          {mutation.isPending ? 'Submitting...' : `${side === 'buy' ? 'Buy' : 'Sell'} ${company.ticker}`}
        </button>
      </form>
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
    margin: '0 0 12px 0',
    fontSize: '16px',
    color: '#fff',
  },
  position: {
    fontSize: '14px',
    color: '#888',
    marginBottom: '16px',
  },
  tabs: {
    display: 'flex',
    gap: '8px',
    marginBottom: '16px',
  },
  tab: {
    flex: 1,
    padding: '8px',
    border: '1px solid #444',
    borderRadius: '4px',
    backgroundColor: 'transparent',
    color: '#888',
    cursor: 'pointer',
    fontSize: '14px',
  },
  tabActiveBuy: {
    backgroundColor: '#4ade80',
    color: '#000',
    borderColor: '#4ade80',
  },
  tabActiveSell: {
    backgroundColor: '#f87171',
    color: '#000',
    borderColor: '#f87171',
  },
  form: {
    display: 'flex',
    flexDirection: 'column',
    gap: '12px',
  },
  field: {
    display: 'flex',
    flexDirection: 'column',
    gap: '4px',
  },
  label: {
    fontSize: '12px',
    color: '#888',
  },
  input: {
    padding: '10px',
    fontSize: '14px',
    borderRadius: '4px',
    border: '1px solid #444',
    backgroundColor: '#2a2a3e',
    color: '#fff',
  },
  total: {
    fontSize: '14px',
    color: '#fff',
    padding: '8px',
    backgroundColor: '#2a2a3e',
    borderRadius: '4px',
    textAlign: 'center',
  },
  error: {
    color: '#f87171',
    fontSize: '14px',
    padding: '8px',
    backgroundColor: 'rgba(248, 113, 113, 0.1)',
    borderRadius: '4px',
  },
  button: {
    padding: '12px',
    fontSize: '14px',
    fontWeight: 'bold',
    borderRadius: '4px',
    border: 'none',
    color: '#000',
    cursor: 'pointer',
  },
};
