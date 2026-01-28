import { useQuery } from '@tanstack/react-query';
import { api } from '../api/client';
import { CompanyCard } from '../components/CompanyCard';

export function CompanyListPage() {
  const { data, isLoading, error } = useQuery({
    queryKey: ['companies'],
    queryFn: api.getCompanies,
  });

  if (isLoading) {
    return <div style={styles.loading}>Loading companies...</div>;
  }

  if (error) {
    return <div style={styles.error}>Failed to load companies</div>;
  }

  const companies = data?.data || [];

  return (
    <div style={styles.container}>
      <h1 style={styles.title}>Pre-IPO Companies</h1>
      <p style={styles.subtitle}>
        Trade shares in the most promising pre-IPO companies
      </p>
      <div style={styles.grid}>
        {companies.map((company) => (
          <CompanyCard key={company.id} company={company} />
        ))}
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
  title: {
    margin: '0 0 8px 0',
    fontSize: '28px',
    color: '#fff',
  },
  subtitle: {
    margin: '0 0 24px 0',
    fontSize: '16px',
    color: '#888',
  },
  grid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))',
    gap: '16px',
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
