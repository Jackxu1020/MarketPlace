import type { Trade } from '../types';

interface Props {
  trades: Trade[];
}

export function TradesFeed({ trades }: Props) {
  const formatPrice = (price: string) => `$${parseFloat(price).toFixed(2)}`;
  const formatTime = (timestamp: string) => {
    return new Date(timestamp).toLocaleTimeString();
  };

  return (
    <div style={styles.container}>
      <h3 style={styles.title}>Recent Trades</h3>
      {trades.length === 0 ? (
        <div style={styles.empty}>No trades yet</div>
      ) : (
        <div style={styles.list}>
          {trades.map((trade) => (
            <div key={trade.id} style={styles.trade}>
              <div style={styles.tradeMain}>
                <span style={styles.quantity}>{trade.quantity.toLocaleString()}</span>
                <span style={styles.at}>@</span>
                <span style={styles.price}>{formatPrice(trade.price)}</span>
              </div>
              <div style={styles.tradeDetails}>
                <span>{trade.buyer_name} ← {trade.seller_name}</span>
                <span style={styles.time}>{formatTime(trade.inserted_at)}</span>
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
    maxHeight: '300px',
    overflowY: 'auto',
  },
  trade: {
    padding: '8px',
    backgroundColor: '#2a2a3e',
    borderRadius: '4px',
  },
  tradeMain: {
    display: 'flex',
    alignItems: 'center',
    gap: '6px',
    marginBottom: '4px',
  },
  quantity: {
    fontSize: '14px',
    fontWeight: 'bold',
    color: '#fff',
  },
  at: {
    color: '#666',
  },
  price: {
    fontSize: '14px',
    color: '#60a5fa',
  },
  tradeDetails: {
    display: 'flex',
    justifyContent: 'space-between',
    fontSize: '12px',
    color: '#888',
  },
  time: {
    color: '#666',
  },
};
