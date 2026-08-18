'use client';

import { useEffect, useRef } from 'react';
import toast from 'react-hot-toast';
import { ordersApi } from '@/lib/api/endpoints';
import { useAuthStore } from '@/lib/store/auth-store';
import { useOrderAlerts } from '@/lib/store/order-alerts';
import { playNotificationTone } from '@/lib/utils/sound';

export default function NewOrderWatcher() {
  const token = useAuthStore((s) => s.token);
  const knownIds = useRef<Set<string>>(new Set());
  const initialized = useRef(false);

  useEffect(() => {
    if (!token) return;

    if (typeof Notification !== 'undefined' && Notification.permission === 'default') {
      Notification.requestPermission().catch(() => {});
    }

    const POLL_MS = 5000;

    const checkOrders = async () => {
      try {
        const res = await ordersApi.list({ page: 1 }).then((r) => r.data);
        const orders: any[] = res?.data || [];

        if (!initialized.current) {
          orders.forEach((o) => knownIds.current.add(o.id));
          initialized.current = true;
          return;
        }

        const seen = new Set(knownIds.current);
        const newlyDetected = orders.filter((o) => !seen.has(o.id));

        if (newlyDetected.length > 0) {
          newlyDetected.forEach((o) => knownIds.current.add(o.id));

          const alerts = newlyDetected.map((o) => ({
            id: o.id,
            order_number: o.order_number,
            customer: o.user?.name || null,
            phone: o.user?.phone || null,
            total: o.total,
            status: o.status,
            created_at: o.created_at,
          }));
          useOrderAlerts.getState().addNewOrders(alerts);

          playNotificationTone();

          // browser notification (optional)
          if (typeof Notification !== 'undefined' && Notification.permission === 'granted') {
            const first = newlyDetected[0];
            new Notification('New Order Received', {
              body: `${first.order_number} — Rs. ${first.total}${first.user?.name ? ' from ' + first.user.name : ''}`,
              tag: first.id,
            });
          }

          // toast per order
          newlyDetected.forEach((o) => {
            toast.custom(
              (t) => (
                <div
                  onClick={() => toast.dismiss(t.id)}
                  className="flex items-start gap-3 bg-white border border-red-200 rounded-xl shadow-lg p-4 min-w-[320px] cursor-pointer"
                >
                  <div className="w-10 h-10 rounded-full bg-red-100 flex items-center justify-center shrink-0">
                    <span className="text-red-600 font-bold">!</span>
                  </div>
                  <div>
                    <p className="text-sm font-semibold text-gray-900">
                      New Order · {o.order_number}
                    </p>
                    <p className="text-sm text-gray-600">
                      {o.user?.name || 'Customer'} —{' '}
                      <span className="font-medium text-gray-900">Rs. {o.total}</span>
                    </p>
                    {o.user?.phone && <p className="text-xs text-gray-500">{o.user.phone}</p>}
                  </div>
                </div>
              ),
              { duration: 8000 }
            );
          });
        }
      } catch {
        // silent — request may fail if not logged in
      }
    };

    checkOrders();
    const interval = setInterval(checkOrders, POLL_MS);
    return () => clearInterval(interval);
  }, [token]);

  return null;
}