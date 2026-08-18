'use client';

import { create } from 'zustand';

export interface OrderAlert {
  id: string;
  order_number: string;
  customer: string | null;
  phone: string | null;
  total: number;
  status: string;
  created_at: string;
}

interface OrderAlertsState {
  unreadCount: number;
  recent: OrderAlert[];
  addNewOrders: (orders: OrderAlert[]) => void;
  markAllRead: () => void;
}

export const useOrderAlerts = create<OrderAlertsState>((set) => ({
  unreadCount: 0,
  recent: [],
  addNewOrders: (orders) =>
    set((s) => ({
      unreadCount: s.unreadCount + orders.length,
      recent: [...orders, ...s.recent].slice(0, 20),
    })),
  markAllRead: () => set({ unreadCount: 0 }),
}));