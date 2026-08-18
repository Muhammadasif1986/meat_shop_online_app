import { apiClient } from './client';

export const authApi = {
  login: (data: { email: string; password: string }) =>
    apiClient.post('/auth/admin/login', data),
  logout: () => apiClient.post('/auth/logout'),
};

export const dashboardApi = {
  getStats: () => apiClient.get('/admin/dashboard/stats'),
  getSales: (days: number = 30) => apiClient.get(`/admin/analytics/sales?days=${days}`),
  getTopProducts: (days: number = 30) =>
    apiClient.get(`/admin/analytics/top-products?days=${days}`),
};

export const ordersApi = {
  list: (params?: { status?: string; today?: boolean; page?: number }) =>
    apiClient.get('/admin/orders', { params }),
  updateStatus: (id: string, data: { status: string; notes?: string }) =>
    apiClient.patch(`/admin/orders/${id}/status`, data),
  assignRider: (id: string, riderId: string) =>
    apiClient.post(`/admin/orders/${id}/assign-rider`, { rider_id: riderId }),
  delete: (id: string) => apiClient.delete(`/admin/orders/${id}`),
};

export const productsApi = {
  list: (params?: { page?: number }) =>
    apiClient.get('/admin/products', { params }),
  create: (data: any) => apiClient.post('/admin/products', data),
  update: (id: string, data: any) =>
    apiClient.patch(`/admin/products/${id}`, data),
  updateStock: (id: string, stockKg: number) =>
    apiClient.patch(`/admin/products/${id}/stock`, { stock_kg: stockKg }),
  delete: (id: string) => apiClient.delete(`/admin/products/${id}`),
};

export const categoriesApi = {
  list: () => apiClient.get('/admin/categories'),
  create: (data: any) => apiClient.post('/admin/categories', data),
  update: (id: string, data: any) =>
    apiClient.patch(`/admin/categories/${id}`, data),
};

export const customersApi = {
  list: (params?: { page?: number }) =>
    apiClient.get('/admin/customers', { params }),
};

export const reviewsApi = {
  list: () => apiClient.get('/admin/reviews'),
  approve: (id: string) => apiClient.patch(`/admin/reviews/${id}/approve`),
};

export const promotionsApi = {
  list: () => apiClient.get('/admin/promotions'),
  create: (data: any) => apiClient.post('/admin/promotions', data),
};

export const ridersApi = {
  list: () => apiClient.get('/admin/riders'),
  create: (data: { name: string; phone: string; email?: string }) =>
    apiClient.post('/admin/riders', data),
  toggleActive: (id: string) =>
    apiClient.patch(`/admin/riders/${id}/toggle-active`),
  delete: (id: string) =>
    apiClient.delete(`/admin/riders/${id}`),
};

export const subscriptionsApi = {
  list: () => apiClient.get('/admin/subscriptions'),
};

export const notificationsApi = {
  list: () => apiClient.get('/admin/notifications'),
  send: (data: { title: string; title_ur?: string; body: string; body_ur?: string; user_id?: string }) =>
    apiClient.post('/admin/notifications/send', data),
};

export const adminApi = {
  getTranslations: (tab: string) => apiClient.get(`/admin/translations/${tab}`),
  updateTranslation: (tab: string, id: string, data: any) =>
    apiClient.patch(`/admin/translations/${tab}/${id}`, data),
};
