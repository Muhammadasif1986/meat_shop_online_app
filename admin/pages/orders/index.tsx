'use client';

import { useState, useEffect } from 'react';
import { useSearchParams } from 'next/navigation';
import DashboardLayout from '@/components/layout/DashboardLayout';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { ordersApi } from '@/lib/api/endpoints';
import { OrderStatus } from '@/lib/types';
import toast from 'react-hot-toast';
import { Trash2 } from 'lucide-react';

const statusColors: Record<string, string> = {
  pending: 'bg-yellow-100 text-yellow-800',
  confirmed: 'bg-blue-100 text-blue-800',
  preparing: 'bg-indigo-100 text-indigo-800',
  cutting: 'bg-purple-100 text-purple-800',
  packed: 'bg-orange-100 text-orange-800',
  rider_assigned: 'bg-cyan-100 text-cyan-800',
  out_for_delivery: 'bg-teal-100 text-teal-800',
  delivered: 'bg-green-100 text-green-800',
  cancelled: 'bg-red-100 text-red-800',
};

const statusFlow: OrderStatus[] = [
  'pending', 'confirmed', 'preparing', 'cutting', 'packed',
  'rider_assigned', 'out_for_delivery', 'delivered',
];

export default function OrdersPage() {
  const searchParams = useSearchParams();
  const [statusFilter, setStatusFilter] = useState<string>(searchParams.get('status') || '');
  const isToday = searchParams.get('today') === '1';
  const queryClient = useQueryClient();

  useEffect(() => {
    const s = searchParams.get('status');
    if (s) setStatusFilter(s);
  }, [searchParams]);

  const { data, isLoading } = useQuery({
    queryKey: ['admin-orders', statusFilter, isToday],
    queryFn: () => ordersApi.list({ status: statusFilter || undefined, today: isToday || undefined }).then(r => r.data),
    refetchInterval: 15000,
  });

  const statusMutation = useMutation({
    mutationFn: ({ id, status }: { id: string; status: string }) =>
      ordersApi.updateStatus(id, { status }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-orders'] });
      toast.success('Order status updated');
    },
    onError: (err: any) => toast.error(err?.response?.data?.detail || err?.response?.data?.message || 'Failed to update order status'),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => ordersApi.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-orders'] });
      toast.success('Order deleted');
    },
    onError: (err: any) => toast.error(err?.response?.data?.detail || err?.response?.data?.message || 'Failed to delete order'),
  });

  const handleDelete = (id: string) => {
    if (confirm('Delete this order permanently? This cannot be undone.')) {
      deleteMutation.mutate(id);
    }
  };

  return (
    <DashboardLayout>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold">Orders</h1>
        <select
          className="border rounded-lg px-4 py-2 text-sm"
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
        >
          <option value="">All Status</option>
          {statusFlow.map((s) => (
            <option key={s} value={s}>{s.replace(/_/g, ' ')}</option>
          ))}
        </select>
      </div>

      {isLoading ? (
        <p className="text-gray-500">Loading...</p>
      ) : (
      <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-x-auto">
        <table className="w-full">
          <thead className="bg-gray-50 border-b">
            <tr>
              <th className="text-left p-4 text-sm font-medium text-gray-500">Order #</th>
              <th className="text-left p-4 text-sm font-medium text-gray-500">Customer</th>
              <th className="text-left p-4 text-sm font-medium text-gray-500">Phone</th>
              <th className="text-left p-4 text-sm font-medium text-gray-500">Address</th>
              <th className="text-left p-4 text-sm font-medium text-gray-500">Items</th>
              <th className="text-left p-4 text-sm font-medium text-gray-500">Total</th>
              <th className="text-left p-4 text-sm font-medium text-gray-500">Status</th>
              <th className="text-left p-4 text-sm font-medium text-gray-500">Date</th>
              <th className="text-left p-4 text-sm font-medium text-gray-500">Actions</th>
            </tr>
          </thead>
          <tbody>
            {data?.data?.length === 0 ? (
              <tr><td colSpan={9} className="p-6 text-center text-gray-400 text-sm">No orders found</td></tr>
            ) : data?.data?.map((order: any) => (
              <tr key={order.id} className="border-b last:border-0 hover:bg-gray-50">
                <td className="p-4 font-medium">{order.order_number}</td>
                <td className="p-4 text-sm text-gray-600">{order.user?.name || '—'}</td>
                <td className="p-4 text-sm text-gray-600">{order.user?.phone || '—'}</td>
                <td className="p-4 text-sm text-gray-600 max-w-[180px] truncate">
                  {order.address?.full_address || '—'}
                </td>
                <td className="p-4 text-sm text-gray-600">
                  <div className="flex flex-col gap-1">
                    {order.items?.length ? order.items.map((item: any, idx: number) => (
                      <div key={idx} className="flex items-center justify-between gap-2">
                        <span className="truncate max-w-[140px]">{item.product_name}</span>
                        <span className="text-xs text-gray-500 shrink-0">{item.weight_kg}kg</span>
                      </div>
                    )) : <span className="text-gray-400">No items</span>}
                  </div>
                </td>
                <td className="p-4 font-medium">Rs. {order.total}</td>
                <td className="p-4">
                  <span className={`px-2 py-1 rounded-full text-xs font-medium ${statusColors[order.status] || ''}`}>
                    {order.status?.replace(/_/g, ' ')}
                  </span>
                </td>
                <td className="p-4 text-sm text-gray-500">
                  {new Date(order.created_at).toLocaleDateString()}
                </td>
                <td className="p-4">
                  <div className="flex items-center gap-2">
                    <select
                      className="border rounded px-2 py-1 text-sm"
                      value={order.status}
                      onChange={(e) => statusMutation.mutate({ id: order.id, status: e.target.value })}
                    >
                      {statusFlow.map((s) => (
                        <option key={s} value={s}>{s.replace(/_/g, ' ')}</option>
                      ))}
                    </select>
                    <button
                      onClick={() => handleDelete(order.id)}
                      className="p-1.5 rounded text-red-600 hover:bg-red-50"
                      title="Delete order"
                    >
                      <Trash2 size={16} />
                    </button>
                  </div>
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
