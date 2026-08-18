'use client';

import DashboardLayout from '@/components/layout/DashboardLayout';
import { useQuery } from '@tanstack/react-query';
import { subscriptionsApi } from '@/lib/api/endpoints';
import { ClipboardList } from 'lucide-react';

export default function SubscriptionsPage() {
  const { data, isLoading } = useQuery({
    queryKey: ['admin-subscriptions'],
    queryFn: () => subscriptionsApi.list().then(r => r.data),
  });

  const subs = data?.data || [];

  return (
    <DashboardLayout>
      <h1 className="text-2xl font-bold mb-6">Subscriptions</h1>

      {isLoading ? (
        <p className="text-gray-500">Loading...</p>
      ) : subs.length === 0 ? (
        <div className="bg-white rounded-xl p-12 shadow-sm border border-gray-100 text-center">
          <ClipboardList size={48} className="mx-auto text-gray-300 mb-4" />
          <p className="text-gray-400 text-sm">No active subscriptions</p>
        </div>
      ) : (
        <div className="space-y-4">
          {subs.map((s: any) => (
            <div key={s.id} className="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
              <div className="flex items-start justify-between">
                <div>
                  <h3 className="font-semibold">{s.plan_name}</h3>
                  <p className="text-sm text-gray-500 mt-1">{s.description}</p>
                  <div className="flex gap-4 mt-3 text-sm text-gray-600">
                    <span>Interval: {s.interval_type} {s.interval_count > 1 ? `(${s.interval_count}x)` : ''}</span>
                    <span>Price: Rs. {s.price_per_cycle}/cycle</span>
                    <span>Remaining: {s.cycles_remaining ?? 0}/{s.total_cycles ?? '∞'}</span>
                  </div>
                  <p className="text-xs text-gray-400 mt-2">
                    Next delivery: {s.next_order_date ? new Date(s.next_order_date).toLocaleDateString() : 'N/A'}
                    {s.delivery_slot ? ` | Slot: ${s.delivery_slot}` : ''}
                  </p>
                </div>
                <span className={`px-3 py-1 rounded-full text-xs font-medium ${
                  s.status === 'active' ? 'bg-green-100 text-green-700' :
                  s.status === 'paused' ? 'bg-yellow-100 text-yellow-700' :
                  'bg-gray-100 text-gray-500'
                }`}>{s.status}</span>
              </div>
            </div>
          ))}
        </div>
      )}
    </DashboardLayout>
  );
}
