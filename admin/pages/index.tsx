'use client';

import { useQuery } from '@tanstack/react-query';
import Link from 'next/link';
import DashboardLayout from '@/components/layout/DashboardLayout';
import { dashboardApi } from '@/lib/api/endpoints';
import { ShoppingCart, DollarSign, Users, Clock, ArrowUpRight } from 'lucide-react';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, BarChart, Bar } from 'recharts';

const statCards = [
  { label: 'Today Orders', key: 'today_orders', icon: ShoppingCart, color: 'bg-blue-500', href: '/orders?today=1' },
  { label: 'Today Revenue', key: 'today_revenue', icon: DollarSign, color: 'bg-green-500', prefix: 'Rs. ', href: '/orders?today=1' },
  { label: 'Total Customers', key: 'total_customers', icon: Users, color: 'bg-purple-500', href: '/customers' },
  { label: 'Pending Orders', key: 'pending_orders', icon: Clock, color: 'bg-orange-500', href: '/orders?status=pending' },
];

export default function DashboardPage() {
  const { data: stats } = useQuery({
    queryKey: ['dashboard-stats'],
    queryFn: () => dashboardApi.getStats().then((res) => res.data.data),
    refetchInterval: 30000,
  });

  const { data: salesData } = useQuery({
    queryKey: ['dashboard-sales'],
    queryFn: () => dashboardApi.getSales(14).then(r => r.data),
  });

  const { data: topProducts } = useQuery({
    queryKey: ['dashboard-top-products'],
    queryFn: () => dashboardApi.getTopProducts(30, 5).then(r => r.data),
  });

  const sales = salesData?.data || [];
  const top = topProducts?.data || [];

  return (
    <DashboardLayout>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        {statCards.map((card) => (
          <Link key={card.key} href={card.href} className="block bg-white rounded-xl p-6 shadow-sm border border-gray-100 hover:shadow-md transition-shadow">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-500">{card.label}</p>
                <p className="text-2xl font-bold mt-1">
                  {card.prefix || ''}
                  {stats?.[card.key as keyof typeof stats] ?? '—'}
                </p>
              </div>
              <div className={`${card.color} p-3 rounded-lg`}>
                <card.icon size={24} className="text-white" />
              </div>
            </div>
            <div className="mt-3 text-xs text-gray-400 flex items-center gap-1">
              View details <ArrowUpRight size={12} />
            </div>
          </Link>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
        <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
          <h3 className="text-lg font-semibold mb-4">Revenue (14 days)</h3>
          {sales.length === 0 ? (
            <p className="text-gray-400 text-sm py-12 text-center">No revenue data yet</p>
          ) : (
            <ResponsiveContainer width="100%" height={250}>
              <AreaChart data={sales}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                <XAxis dataKey="date" tick={{ fontSize: 11 }} tickFormatter={(v) => v?.slice(5) || ''} />
                <YAxis tick={{ fontSize: 11 }} />
                <Tooltip />
                <Area type="monotone" dataKey="revenue" stroke="#991b1b" fill="#fee2e2" name="Revenue" />
              </AreaChart>
            </ResponsiveContainer>
          )}
        </div>
        <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
          <h3 className="text-lg font-semibold mb-4">Orders (14 days)</h3>
          {sales.length === 0 ? (
            <p className="text-gray-400 text-sm py-12 text-center">No order data yet</p>
          ) : (
            <ResponsiveContainer width="100%" height={250}>
              <BarChart data={sales}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                <XAxis dataKey="date" tick={{ fontSize: 11 }} tickFormatter={(v) => v?.slice(5) || ''} />
                <YAxis tick={{ fontSize: 11 }} />
                <Tooltip />
                <Bar dataKey="orders" fill="#991b1b" name="Orders" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          )}
        </div>
      </div>

      <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
        <h3 className="text-lg font-semibold mb-4">Top Products</h3>
        {top.length === 0 ? (
          <p className="text-gray-400 text-sm py-8 text-center">No product data yet</p>
        ) : (
          <div className="space-y-3">
            {top.map((p: any, i: number) => (
              <div key={p.product_name} className="flex items-center justify-between py-2 border-b last:border-0">
                <div className="flex items-center gap-3">
                  <span className="w-6 h-6 rounded-full bg-red-900 text-white text-xs flex items-center justify-center font-medium">{i + 1}</span>
                  <span className="text-sm font-medium">{p.product_name}</span>
                </div>
                <div className="flex gap-6 text-sm text-gray-600">
                  <span>{p.order_count} orders</span>
                  <span>{Number(p.total_kg).toFixed(1)} kg</span>
                  <span className="font-medium text-gray-900">Rs. {Number(p.total_sales).toLocaleString()}</span>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </DashboardLayout>
  );
}
