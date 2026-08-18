'use client';

import { ReactNode } from 'react';
import Sidebar from './Sidebar';
import Header from './Header';
import NewOrderWatcher from './NewOrderWatcher';
import { LanguageProvider } from '@/lib/i18n/context';

export default function DashboardLayout({ children }: { children: ReactNode }) {
  return (
    <LanguageProvider>
      <NewOrderWatcher />
      <div className="flex min-h-screen bg-gray-50">
        <Sidebar />
        <div className="flex-1 flex flex-col">
          <Header />
          <main className="flex-1 p-6">{children}</main>
        </div>
      </div>
    </LanguageProvider>
  );
}
