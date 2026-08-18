'use client';

import { useState } from 'react';
import DashboardLayout from '@/components/layout/DashboardLayout';
import { useQuery } from '@tanstack/react-query';
import { customersApi } from '@/lib/api/endpoints';

export default function CustomersPage() {
  const [search, setSearch] = useState('');
  const { data, isLoading } = useQuery({
    queryKey: ['admin-customers'],
    queryFn: () => customersApi.list().then(r => r.data),
  });

  const filtered = data?.data?.filter((c: any) =>
    !search || c.name?.toLowerCase().includes(search.toLowerCase()) || c.phone?.includes(search)
  );

  return (
    <DashboardLayout>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold">Customers</h1>
        <input
          className="border rounded-lg px-4 py-2 text-sm w-64"
          placeholder="Search by name or phone..."
          value={search} onChange={e => setSearch(e.target.value)}
        />
      </div>

      {isLoading ? (
        <p className="text-gray-500">Loading...</p>
      ) : (
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 border-b">
              <tr>
                <th className="text-left p-3 text-xs font-medium text-gray-500 uppercase">Name</th>
                <th className="text-left p-3 text-xs font-medium text-gray-500 uppercase">Phone</th>
                <th className="text-left p-3 text-xs font-medium text-gray-500 uppercase">Orders</th>
                <th className="text-left p-3 text-xs font-medium text-gray-500 uppercase">Total Spent</th>
                <th className="text-left p-3 text-xs font-medium text-gray-500 uppercase">Last Order</th>
                <th className="text-left p-3 text-xs font-medium text-gray-500 uppercase">Joined</th>
                <th className="text-left p-3 text-xs font-medium text-gray-500 uppercase">Status</th>
              </tr>
            </thead>
            <tbody>
              {filtered?.length === 0 ? (
                <tr><td colSpan={7} className="p-6 text-center text-gray-400 text-sm">No customers found</td></tr>
              ) : filtered?.map((c: any) => (
                <tr key={c.id} className="border-b last:border-0 hover:bg-gray-50">
                  <td className="p-3 text-sm font-medium">{c.name || '—'}</td>
                  <td className="p-3 text-sm">{c.phone}</td>
                  <td className="p-3 text-sm">{c.total_orders ?? 0}</td>
                  <td className="p-3 text-sm">Rs. {(c.total_spent ?? 0).toLocaleString()}</td>
                  <td className="p-3 text-sm">{c.last_order_at ? new Date(c.last_order_at).toLocaleDateString() : '—'}</td>
                  <td className="p-3 text-sm">{new Date(c.created_at).toLocaleDateString()}</td>
                  <td className="p-3">
                    <span className={`px-2 py-1 rounded-full text-xs ${c.is_active ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}>
                      {c.is_active ? 'Active' : 'Inactive'}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </DashboardLayout>
  );
}
