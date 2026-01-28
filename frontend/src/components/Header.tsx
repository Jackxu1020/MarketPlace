import { Link } from 'react-router-dom';
import { useUser } from '../contexts/UserContext';

export function Header() {
  const { users, currentUser, setCurrentUserId, isLoading } = useUser();

  const formatCurrency = (value: string) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
    }).format(parseFloat(value));
  };

  return (
    <header style={styles.header}>
      <Link to="/" style={styles.logo}>
        Jack's Marketplace
      </Link>

      <div style={styles.userSection}>
        <select
          value={currentUser?.id || ''}
          onChange={(e) => setCurrentUserId(e.target.value ? Number(e.target.value) : null)}
          style={styles.select}
          disabled={isLoading}
        >
          <option value="">Select User</option>
          {users.map((user) => (
            <option key={user.id} value={user.id}>
              {user.name}
            </option>
          ))}
        </select>

        {currentUser && (
          <span style={styles.balance}>
            Balance: {formatCurrency(currentUser.cash_balance)}
          </span>
        )}
      </div>
    </header>
  );
}

const styles: Record<string, React.CSSProperties> = {
  header: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: '16px 24px',
    backgroundColor: '#1a1a2e',
    borderBottom: '1px solid #333',
  },
  logo: {
    fontSize: '20px',
    fontWeight: 'bold',
    color: '#fff',
    textDecoration: 'none',
  },
  userSection: {
    display: 'flex',
    alignItems: 'center',
    gap: '16px',
  },
  select: {
    padding: '8px 12px',
    fontSize: '14px',
    borderRadius: '4px',
    border: '1px solid #444',
    backgroundColor: '#2a2a3e',
    color: '#fff',
    cursor: 'pointer',
  },
  balance: {
    color: '#4ade80',
    fontWeight: '500',
  },
};
