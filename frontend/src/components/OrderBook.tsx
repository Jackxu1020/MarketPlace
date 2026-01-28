import type { OrderBook as OrderBookType } from '../types';
import { useUser } from '../contexts/UserContext';

interface Props {
  orderBook: OrderBookType | null;
}

export function OrderBook({ orderBook }: Props) {
  const { currentUser } = useUser();

  if (!orderBook) {
    return <div style={styles.loading}>Loading order book...</div>;
  }

  const formatPrice = (price: string) => `$${parseFloat(price).toFixed(2)}`;

  const aggregateOrders = (orders: typeof orderBook.bids) => {
    const grouped = new Map<string, { quantity: number; isOwn: boolean }>();
    for (const order of orders) {
      const existing = grouped.get(order.price) || { quantity: 0, isOwn: false };
      grouped.set(order.price, {
        quantity: existing.quantity + order.quantity,
        isOwn: existing.isOwn || order.user_id === currentUser?.id,
      });
    }
    return Array.from(grouped.entries()).map(([price, data]) => ({
      price,
      ...data,
    }));
  };

  const bids = aggregateOrders(orderBook.bids);
  const asks = aggregateOrders(orderBook.asks);

  return (
    <div style={styles.container}>
      <h3 style={styles.title}>Order Book</h3>
      <div style={styles.book}>
        <div style={styles.side}>
          <div style={styles.sideHeader}>
            <span>Bids</span>
          </div>
          <div style={styles.headerRow}>
            <span>Price</span>
            <span>Qty</span>
          </div>
          {bids.length === 0 ? (
            <div style={styles.empty}>No bids</div>
          ) : (
            bids.map((bid, i) => (
              <div
                key={i}
                style={{
                  ...styles.row,
                  backgroundColor: bid.isOwn ? 'rgba(74, 222, 128, 0.1)' : 'transparent',
                }}
              >
                <span style={styles.bidPrice}>{formatPrice(bid.price)}</span>
                <span>{bid.quantity.toLocaleString()}</span>
              </div>
            ))
          )}
        </div>

        <div style={styles.side}>
          <div style={styles.sideHeader}>
            <span>Asks</span>
          </div>
          <div style={styles.headerRow}>
            <span>Price</span>
            <span>Qty</span>
          </div>
          {asks.length === 0 ? (
            <div style={styles.empty}>No asks</div>
          ) : (
            asks.map((ask, i) => (
              <div
                key={i}
                style={{
                  ...styles.row,
                  backgroundColor: ask.isOwn ? 'rgba(248, 113, 113, 0.1)' : 'transparent',
                }}
              >
                <span style={styles.askPrice}>{formatPrice(ask.price)}</span>
                <span>{ask.quantity.toLocaleString()}</span>
              </div>
            ))
          )}
        </div>
      </div>
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
  book: {
    display: 'grid',
    gridTemplateColumns: '1fr 1fr',
    gap: '16px',
  },
  side: {
    display: 'flex',
    flexDirection: 'column',
  },
  sideHeader: {
    fontSize: '14px',
    fontWeight: 'bold',
    marginBottom: '8px',
    color: '#888',
  },
  headerRow: {
    display: 'flex',
    justifyContent: 'space-between',
    fontSize: '12px',
    color: '#666',
    padding: '4px 0',
    borderBottom: '1px solid #333',
  },
  row: {
    display: 'flex',
    justifyContent: 'space-between',
    fontSize: '14px',
    padding: '6px 4px',
    borderBottom: '1px solid #222',
  },
  bidPrice: {
    color: '#4ade80',
  },
  askPrice: {
    color: '#f87171',
  },
  empty: {
    color: '#666',
    fontSize: '14px',
    padding: '16px 0',
    textAlign: 'center',
  },
  loading: {
    color: '#666',
    padding: '32px',
    textAlign: 'center',
  },
};
