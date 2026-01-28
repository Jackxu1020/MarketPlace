import { useParams, Link } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { api } from '../api/client';
import { useCompanyChannel } from '../hooks/useCompanyChannel';
import { OrderBook } from '../components/OrderBook';
import { OrderForm } from '../components/OrderForm';
import { TradesFeed } from '../components/TradesFeed';
import { MyOrders } from '../components/MyOrders';
import { useUser } from '../contexts/UserContext';

export function CompanyDetailPage() {
  const { id } = useParams<{ id: string }>();
  const companyId = id ? parseInt(id, 10) : null;
  const { currentUser } = useUser();

  const { data, isLoading, error } = useQuery({
    queryKey: ['company', companyId],
    queryFn: () => api.getCompany(companyId!),
    enabled: companyId !== null,
  });

  const { orderBook, recentTrades, isConnected } = useCompanyChannel(companyId);

  if (isLoading) {
    return <div style={styles.loading}>Loading company...</div>;
  }

  if (error || !data?.data) {
    return (
      <div style={styles.error}>
        <p>Failed to load company</p>
        <Link to="/" style={styles.backLink}>Back to companies</Link>
      </div>
    );
  }

  const company = data.data;
  const userHolding = currentUser?.holdings?.find((h) => h.company_id === company.id);

  const formatValuation = (value: string) => {
    const num = parseFloat(value);
    if (num >= 1e9) return `$${(num / 1e9).toFixed(1)}B`;
    if (num >= 1e6) return `$${(num / 1e6).toFixed(1)}M`;
    return `$${num.toLocaleString()}`;
  };

  return (
    <div style={styles.container}>
      <Link to="/" style={styles.backLink}>← Back to companies</Link>

      <div style={styles.header}>
        <div>
          <div style={styles.tickerRow}>
            <h1 style={styles.ticker}>{company.ticker}</h1>
            <span style={styles.sector}>{company.sector}</span>
            {isConnected && <span style={styles.connected}>● Live</span>}
          </div>
          <h2 style={styles.name}>{company.name}</h2>
          <p style={styles.description}>{company.description}</p>
        </div>
        <div style={styles.stats}>
          <div style={styles.stat}>
            <span style={styles.statLabel}>Valuation</span>
            <span style={styles.statValue}>{formatValuation(company.valuation)}</span>
          </div>
          {userHolding && (
            <div style={styles.stat}>
              <span style={styles.statLabel}>Your Position</span>
              <span style={styles.statValue}>{userHolding.quantity.toLocaleString()} shares</span>
            </div>
          )}
        </div>
      </div>

      <div style={styles.content}>
        <div style={styles.mainColumn}>
          <OrderBook orderBook={orderBook} />
          <TradesFeed trades={recentTrades} />
        </div>
        <div style={styles.sideColumn}>
          <OrderForm company={company} />
          <MyOrders company={company} />
        </div>
      </div>
    </div>
  );
}

const styles: Record<string, React.CSSProperties> = {
  container: {
    padding: '24px',
    maxWidth: '1200px',
    margin: '0 auto',
  },
  backLink: {
    color: '#60a5fa',
    textDecoration: 'none',
    fontSize: '14px',
    display: 'inline-block',
    marginBottom: '16px',
  },
  header: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: '24px',
    padding: '24px',
    backgroundColor: '#1a1a2e',
    borderRadius: '8px',
    border: '1px solid #333',
  },
  tickerRow: {
    display: 'flex',
    alignItems: 'center',
    gap: '12px',
    marginBottom: '4px',
  },
  ticker: {
    margin: 0,
    fontSize: '24px',
    color: '#60a5fa',
  },
  sector: {
    fontSize: '12px',
    color: '#888',
    backgroundColor: '#2a2a3e',
    padding: '4px 8px',
    borderRadius: '4px',
  },
  connected: {
    fontSize: '12px',
    color: '#4ade80',
  },
  name: {
    margin: '0 0 8px 0',
    fontSize: '20px',
    color: '#fff',
    fontWeight: 'normal',
  },
  description: {
    margin: 0,
    fontSize: '14px',
    color: '#888',
  },
  stats: {
    display: 'flex',
    gap: '24px',
  },
  stat: {
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'flex-end',
  },
  statLabel: {
    fontSize: '12px',
    color: '#888',
  },
  statValue: {
    fontSize: '18px',
    color: '#fff',
    fontWeight: 'bold',
  },
  content: {
    display: 'grid',
    gridTemplateColumns: '2fr 1fr',
    gap: '24px',
  },
  mainColumn: {
    display: 'flex',
    flexDirection: 'column',
    gap: '24px',
  },
  sideColumn: {
    display: 'flex',
    flexDirection: 'column',
    gap: '24px',
  },
  loading: {
    padding: '48px',
    textAlign: 'center',
    color: '#888',
  },
  error: {
    padding: '48px',
    textAlign: 'center',
    color: '#f87171',
  },
};
