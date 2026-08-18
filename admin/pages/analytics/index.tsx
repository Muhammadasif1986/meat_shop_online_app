'use client';

import { useState } from 'react';
import DashboardLayout from '@/components/layout/DashboardLayout';
import { useQuery } from '@tanstack/react-query';
import { dashboardApi } from '@/lib/api/endpoints';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, AreaChart, Area } from 'recharts';

export default function AnalyticsPage() {
  const [days, setDays] = useState(30);

  const { data: salesData } = useQuery({
    queryKey: ['admin-sales', days],
    queryFn: () => dashboardApi.getSales(days).then(r => r.data),
  });

  const { data: topProducts } = useQuery({
    queryKey: ['admin-top-products', days],
    queryFn: () => dashboardApi.getTopProducts(days).then(r => r.data),
  });

  const sales = salesData?.data || [];
  const top = topProducts?.data || [];

  return (
    <DashboardLayout>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-xl sm:text-2xl font-bold">Analytics</h1>
        <select className="border rounded-lg px-4 py-2 text-sm" value={days} onChange={e => setDays(Number(e.target.value))}>
          <option value={7}>Last 7 days</option>
          <option value={30}>Last 30 days</option>
          <option value={90}>Last 90 days</option>
        </select>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
        {/* Sales Chart */}
        <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
          <h3 className="text-lg font-semibold mb-4">Sales Revenue</h3>
          {sales.length === 0 ? (
            <p className="text-gray-400 text-sm py-12 text-center">No sales data yet</p>
          ) : (
            <ResponsiveContainer width="100%" height={300}>
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

        {/* Orders Chart */}
        <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
          <h3 className="text-lg font-semibold mb-4">Orders Over Time</h3>
          {sales.length === 0 ? (
            <p className="text-gray-400 text-sm py-12 text-center">No orders data yet</p>
          ) : (
            <ResponsiveContainer width="100%" height={300}>
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

      {/* Top Products */}
      <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
        <h3 className="text-lg font-semibold mb-4">Top Products</h3>
        {top.length === 0 ? (
          <p className="text-gray-400 text-sm py-8 text-center">No product sales data yet</p>
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
