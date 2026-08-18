'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  LayoutDashboard, ShoppingCart, Package, Users, BarChart3,
  Tag, Star, Truck, Settings, Bell, ClipboardList, Languages,
} from 'lucide-react';
import { useTranslation } from '@/lib/i18n/context';

const menuItems = [
  { labelKey: 'nav.dashboard', icon: LayoutDashboard, href: '/' },
  { labelKey: 'nav.orders', icon: ShoppingCart, href: '/orders' },
  { labelKey: 'nav.products', icon: Package, href: '/products' },
  { labelKey: 'nav.customers', icon: Users, href: '/customers' },
  { labelKey: 'nav.analytics', icon: BarChart3, href: '/analytics' },
  { labelKey: 'nav.promotions', icon: Tag, href: '/promotions' },
  { labelKey: 'nav.reviews', icon: Star, href: '/reviews' },
  { labelKey: 'nav.riders', icon: Truck, href: '/riders' },
  { labelKey: 'nav.subscriptions', icon: ClipboardList, href: '/subscriptions' },
  { labelKey: 'nav.notifications', icon: Bell, href: '/notifications' },
  { labelKey: 'nav.translations', icon: Languages, href: '/translations' },
  { labelKey: 'nav.settings', icon: Settings, href: '/settings' },
];

export default function Sidebar() {
  const pathname = usePathname();
  const { t, isRtl } = useTranslation();

  return (
    <aside
      className={`w-64 bg-white border-r min-h-screen ${isRtl ? 'border-l' : 'border-r-gray-200'}`}
      style={isRtl ? { borderLeft: '1px solid #e5e7eb', borderRight: 'none' } : {}}
    >
      <div className="p-6 border-b border-gray-200">
        <h1 className="text-xl font-bold text-red-900">{t('app.name')}</h1>
        <p className="text-sm text-gray-500">{t('app.tagline')}</p>
      </div>
      <nav className="p-4 space-y-1">
        {menuItems.map((item) => {
          const isActive = pathname === item.href || pathname.startsWith(item.href + '/');
          return (
            <Link
              key={item.href}
              href={item.href}
              className={`flex items-center gap-3 px-4 py-3 rounded-lg text-sm font-medium transition-colors ${
                isActive
                  ? 'bg-red-50 text-red-900'
                  : 'text-gray-600 hover:bg-gray-50'
              }`}
            >
              <item.icon size={20} />
              {t(item.labelKey)}
            </Link>
          );
        })}
      </nav>
    </aside>
  );
}
