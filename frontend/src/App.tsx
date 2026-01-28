import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { UserProvider } from './contexts/UserContext';
import { Header } from './components/Header';
import { CompanyListPage } from './pages/CompanyListPage';
import { CompanyDetailPage } from './pages/CompanyDetailPage';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 10000,
      retry: 1,
    },
  },
});

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <UserProvider>
        <BrowserRouter>
          <div style={styles.app}>
            <Header />
            <main style={styles.main}>
              <Routes>
                <Route path="/" element={<CompanyListPage />} />
                <Route path="/company/:id" element={<CompanyDetailPage />} />
              </Routes>
            </main>
          </div>
        </BrowserRouter>
      </UserProvider>
    </QueryClientProvider>
  );
}

const styles: Record<string, React.CSSProperties> = {
  app: {
    minHeight: '100vh',
    backgroundColor: '#0f0f1a',
    color: '#fff',
  },
  main: {
    minHeight: 'calc(100vh - 60px)',
  },
};

export default App;
