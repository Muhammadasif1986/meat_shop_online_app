'use client';

import { ReactNode, useState } from 'react';
import { X } from 'lucide-react';
import Sidebar from './Sidebar';
import Header from './Header';
import NewOrderWatcher from './NewOrderWatcher';
import { LanguageProvider } from '@/lib/i18n/context';

export default function DashboardLayout({ children }: { children: ReactNode }) {
  const [sidebarOpen, setSidebarOpen] = useState(false);

  return (
    <LanguageProvider>
      <NewOrderWatcher />
      <div className="flex min-h-screen bg-gray-50">
        {/* Mobile drawer overlay */}
        {sidebarOpen && (
          <div
            className="fixed inset-0 bg-black/40 z-40 lg:hidden"
            onClick={() => setSidebarOpen(false)}
          />
        )}

        {/* Desktop sidebar: fixed. Mobile: drawer */}
        <div
          className={`fixed inset-y-0 left-0 z-50 transform transition-transform duration-200 lg:static lg:transform-none ${
            sidebarOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'
          }`}
        >
          <div className="relative h-full">
            <button
              onClick={() => setSidebarOpen(false)}
              className="absolute top-4 right-4 p-1.5 rounded-lg text-gray-500 hover:bg-gray-100 lg:hidden"
              aria-label="Close menu"
            >
              <X size={20} />
            </button>
            <Sidebar />
          </div>
        </div>

        <div className="flex-1 flex flex-col min-w-0">
          <Header onMenuClick={() => setSidebarOpen(true)} />
          <main className="flex-1 p-4 sm:p-6">{children}</main>
        </div>
      </div>
    </LanguageProvider>
  );
}
