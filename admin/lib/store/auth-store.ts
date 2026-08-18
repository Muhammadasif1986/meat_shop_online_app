'use client';

import { create } from 'zustand';

interface AuthState {
  token: string | null;
  user: { name: string; email: string; role: string } | null;
  setAuth: (token: string, user: { name: string; email: string; role: string }) => void;
  logout: () => void;
}

export const useAuthStore = create<AuthState>((set) => ({
  token: typeof window !== 'undefined' ? localStorage.getItem('admin_token') : null,
  user: typeof window !== 'undefined'
    ? JSON.parse(localStorage.getItem('admin_user') || 'null')
    : null,
  setAuth: (token, user) => {
    localStorage.setItem('admin_token', token);
    localStorage.setItem('admin_user', JSON.stringify(user));
    set({ token, user });
  },
  logout: () => {
    localStorage.removeItem('admin_token');
    localStorage.removeItem('admin_user');
    set({ token: null, user: null });
  },
}));
