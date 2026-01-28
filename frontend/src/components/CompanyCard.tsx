import { Link } from 'react-router-dom';
import type { Company } from '../types';

interface Props {
  company: Company;
}

export function CompanyCard({ company }: Props) {
  const formatValuation = (value: string) => {
    const num = parseFloat(value);
    if (num >= 1e9) return `$${(num / 1e9).toFixed(1)}B`;
    if (num >= 1e6) return `$${(num / 1e6).toFixed(1)}M`;
    return `$${num.toLocaleString()}`;
  };

  return (
    <Link to={`/company/${company.id}`} style={styles.card}>
      <div style={styles.header}>
        <span style={styles.ticker}>{company.ticker}</span>
        <span style={styles.sector}>{company.sector}</span>
      </div>
      <h3 style={styles.name}>{company.name}</h3>
      <p style={styles.description}>{company.description}</p>
      <div style={styles.footer}>
        <span>Valuation: {formatValuation(company.valuation)}</span>
      </div>
    </Link>
  );
}

const styles: Record<string, React.CSSProperties> = {
  card: {
    display: 'block',
    padding: '20px',
    backgroundColor: '#1a1a2e',
    borderRadius: '8px',
    border: '1px solid #333',
    textDecoration: 'none',
    color: 'inherit',
    transition: 'border-color 0.2s',
  },
  header: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: '8px',
  },
  ticker: {
    fontSize: '14px',
    fontWeight: 'bold',
    color: '#60a5fa',
  },
  sector: {
    fontSize: '12px',
    color: '#888',
    backgroundColor: '#2a2a3e',
    padding: '2px 8px',
    borderRadius: '4px',
  },
  name: {
    margin: '0 0 8px 0',
    fontSize: '18px',
    color: '#fff',
  },
  description: {
    margin: '0 0 16px 0',
    fontSize: '14px',
    color: '#aaa',
    lineHeight: '1.4',
  },
  footer: {
    fontSize: '14px',
    color: '#888',
  },
};
