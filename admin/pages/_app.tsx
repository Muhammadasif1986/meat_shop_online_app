import type { AppProps } from 'next/app';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { Toaster } from 'react-hot-toast';
import { useEffect, useState } from 'react';
import { useRouter } from 'next/router';
import { useAuthStore } from '../lib/store/auth-store';
import '../styles/globals.css';

const queryClient = new QueryClient();

function RTLProvider({ children }: { children: React.ReactNode }) {
  const [dir, setDir] = useState<'ltr' | 'rtl'>('ltr');

  useEffect(() => {
    const locale = localStorage.getItem('admin-locale');
    if (locale === 'ur') setDir('rtl');
    const handler = (e: StorageEvent) => {
      if (e.key === 'admin-locale') setDir(e.newValue === 'ur' ? 'rtl' : 'ltr');
    };
    window.addEventListener('storage', handler);
    return () => window.removeEventListener('storage', handler);
  }, []);

  return <div dir={dir}>{children}</div>;
}

function AuthGuard({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const token = useAuthStore((s) => s.token);

  useEffect(() => {
    if (router.pathname.startsWith('/auth')) return;
    if (!token) router.replace('/auth/login');
  }, [token, router]);

  return <>{children}</>;
}

export default function App({ Component, pageProps }: AppProps) {
  return (
    <QueryClientProvider client={queryClient}>
      <RTLProvider>
        <AuthGuard>
          <Component {...pageProps} />
          <Toaster position="top-right" />
        </AuthGuard>
      </RTLProvider>
    </QueryClientProvider>
  );
}
