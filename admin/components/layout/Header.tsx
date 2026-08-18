'use client';

import { Bell, LogOut, User, Globe } from 'lucide-react';
import { useAuthStore } from '@/lib/store/auth-store';
import { useOrderAlerts } from '@/lib/store/order-alerts';
import { useTranslation } from '@/lib/i18n/context';
import { useState, useRef, useEffect } from 'react';
import { useRouter } from 'next/navigation';

export default function Header() {
  const { user, logout } = useAuthStore();
  const { t, locale, setLocale } = useTranslation();
  const { unreadCount, recent, markAllRead } = useOrderAlerts();
  const [open, setOpen] = useState(false);
  const [alertsOpen, setAlertsOpen] = useState(false);
  const [mounted, setMounted] = useState(false);
  const ref = useRef<HTMLDivElement>(null);
  const alertsRef = useRef<HTMLDivElement>(null);
  const router = useRouter();

  useEffect(() => {
    setMounted(true);
    function handleClick(e: MouseEvent) {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false);
      if (alertsRef.current && !alertsRef.current.contains(e.target as Node)) setAlertsOpen(false);
    }
    document.addEventListener('mousedown', handleClick);
    return () => document.removeEventListener('mousedown', handleClick);
  }, []);

  if (!mounted) return null;

  return (
    <header className="h-16 bg-white border-b border-gray-200 flex items-center justify-between px-6">
      <div className="flex items-center gap-4">
        <h2 className="text-lg font-semibold text-gray-800">{t('header.welcome')}, {user?.name || 'Admin'}</h2>
      </div>
      <div className="flex items-center gap-4">
        {/* New Orders Bell */}
        <div ref={alertsRef} className="relative">
          <button
            onClick={() => {
              setAlertsOpen(!alertsOpen);
              if (!alertsOpen) markAllRead();
            }}
            className="p-2 hover:bg-gray-100 rounded-full relative"
            title={`New orders: ${unreadCount}`}
          >
            <Bell size={20} className="text-gray-600" />
            {unreadCount > 0 && (
              <span className="absolute -top-0.5 -right-0.5 w-4 h-4 bg-red-500 text-white rounded-full text-[10px] flex items-center justify-center font-bold">
                {unreadCount > 9 ? '9+' : unreadCount}
              </span>
            )}
          </button>
          {alertsOpen && (
            <div className="absolute right-0 mt-1 w-80 bg-white border rounded-lg shadow-lg z-50 overflow-hidden">
              <div className="px-4 py-2 border-b text-sm font-semibold text-gray-700">
                New Orders Pulldown
              </div>
              {recent.length === 0 ? (
                <div className="px-4 py-6 text-center text-sm text-gray-500">No recent orders</div>
              ) : (
                <div className="max-h-72 overflow-y-auto">
                  {recent.slice(0, 8).map((o) => (
                    <button
                      key={o.id}
                      onClick={() => { setAlertsOpen(false); router.push('/orders?status=pending'); }}
                      className="w-full text-left px-4 py-3 border-b last:border-0 hover:bg-gray-50"
                    >
                      <div className="flex items-center justify-between">
                        <span className="text-sm font-medium text-gray-900">{o.order_number}</span>
                        <span className="text-sm font-semibold text-red-600">Rs. {o.total}</span>
                      </div>
                      <div className="text-xs text-gray-500 mt-0.5">
                        {o.customer || 'Customer'}
                        {o.phone ? ` · ${o.phone}` : ''}
                      </div>
                    </button>
                  ))}
                </div>
              )}
            </div>
          )}
        </div>

        {/* Language Switcher */}
        <div ref={ref} className="relative">
          <button
            onClick={() => setOpen(!open)}
            className="flex items-center gap-2 px-3 py-2 hover:bg-gray-100 rounded-lg text-sm"
          >
            <Globe size={18} className="text-gray-600" />
            <span className="text-gray-600">{locale === 'ur' ? 'اردو' : 'EN'}</span>
          </button>
          {open && (
            <div className="absolute right-0 mt-1 w-36 bg-white border rounded-lg shadow-lg py-1 z-50">
              <button
                onClick={() => { setLocale('en'); setOpen(false); }}
                className={`w-full text-left px-4 py-2 text-sm hover:bg-gray-50 ${locale === 'en' ? 'bg-red-50 text-red-900 font-medium' : 'text-gray-700'}`}
              >
                English
              </button>
              <button
                onClick={() => { setLocale('ur'); setOpen(false); }}
                className={`w-full text-left px-4 py-2 text-sm hover:bg-gray-50 ${locale === 'ur' ? 'bg-red-50 text-red-900 font-medium' : 'text-gray-700'}`}
              >
                اردو
              </button>
            </div>
          )}
        </div>

        <button className="flex items-center gap-2 px-3 py-2 hover:bg-gray-100 rounded-lg">
          <User size={20} className="text-gray-600" />
          <span className="text-sm text-gray-600">{user?.email}</span>
        </button>
        <button onClick={logout} className="p-2 hover:bg-gray-100 rounded-full">
          <LogOut size={20} className="text-gray-600" />
        </button>
      </div>
    </header>
  );
}
