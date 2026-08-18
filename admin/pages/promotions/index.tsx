'use client';

import { useState } from 'react';
import DashboardLayout from '@/components/layout/DashboardLayout';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { promotionsApi } from '@/lib/api/endpoints';
import toast from 'react-hot-toast';

export default function PromotionsPage() {
  const queryClient = useQueryClient();
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({
    code: '', description: '', description_ur: '',
    discount_type: 'percentage', discount_value: '',
    min_order_amount: 0, max_uses: 0, per_user_limit: 1,
    is_active: true, banner_url: '', banner_url_ur: '',
  });

  const { data, isLoading } = useQuery({
    queryKey: ['admin-promotions'],
    queryFn: () => promotionsApi.list().then(r => r.data),
  });

  const createMut = useMutation({
    mutationFn: (d: any) => promotionsApi.create(d),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-promotions'] });
      setShowForm(false);
      toast.success('Promotion created');
    },
    onError: (err: any) => toast.error(err?.response?.data?.detail || err?.response?.data?.message || 'Failed to create promotion'),
  });

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    createMut.mutate({
      ...form,
      discount_value: Number(form.discount_value),
      min_order_amount: Number(form.min_order_amount),
      max_uses: form.max_uses ? Number(form.max_uses) : undefined,
      per_user_limit: Number(form.per_user_limit),
    });
  }

  return (
    <DashboardLayout>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold">Promotions</h1>
        <button onClick={() => setShowForm(!showForm)}
          className="bg-red-900 text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-red-800">
          {showForm ? 'Cancel' : '+ New Promotion'}
        </button>
      </div>

      {showForm && (
        <form onSubmit={handleSubmit} className="bg-white rounded-xl p-6 shadow-sm border border-gray-100 mb-6">
          <h3 className="text-lg font-semibold mb-4">New Promotion</h3>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
            <div>
              <label className="block text-xs font-medium text-gray-500 mb-1">Code</label>
              <input className="w-full border rounded-lg px-3 py-2 text-sm uppercase" value={form.code} onChange={e => setForm({...form, code: e.target.value})} required />
            </div>
            <div>
              <label className="block text-xs font-medium text-gray-500 mb-1">Discount Type</label>
              <select className="w-full border rounded-lg px-3 py-2 text-sm" value={form.discount_type} onChange={e => setForm({...form, discount_type: e.target.value})}>
                <option value="percentage">Percentage (%)</option>
                <option value="fixed">Fixed (Rs.)</option>
              </select>
            </div>
            <div>
              <label className="block text-xs font-medium text-gray-500 mb-1">Discount Value</label>
              <input type="number" step="0.1" className="w-full border rounded-lg px-3 py-2 text-sm" value={form.discount_value} onChange={e => setForm({...form, discount_value: e.target.value})} required />
            </div>
            <div>
              <label className="block text-xs font-medium text-gray-500 mb-1">Min Order Amount (Rs.)</label>
              <input type="number" className="w-full border rounded-lg px-3 py-2 text-sm" value={form.min_order_amount} onChange={e => setForm({...form, min_order_amount: e.target.value})} />
            </div>
            <div>
              <label className="block text-xs font-medium text-gray-500 mb-1">Max Uses</label>
              <input type="number" className="w-full border rounded-lg px-3 py-2 text-sm" value={form.max_uses} onChange={e => setForm({...form, max_uses: e.target.value})} placeholder="Unlimited" />
            </div>
            <div>
              <label className="block text-xs font-medium text-gray-500 mb-1">Per User Limit</label>
              <input type="number" className="w-full border rounded-lg px-3 py-2 text-sm" value={form.per_user_limit} onChange={e => setForm({...form, per_user_limit: e.target.value})} />
            </div>
            <div className="md:col-span-2">
              <label className="block text-xs font-medium text-gray-500 mb-1">Description (English)</label>
              <textarea className="w-full border rounded-lg px-3 py-2 text-sm" rows={2} value={form.description} onChange={e => setForm({...form, description: e.target.value})} />
            </div>
            <div>
              <label className="block text-xs font-medium text-gray-500 mb-1">Description (Urdu)</label>
              <textarea className="w-full border rounded-lg px-3 py-2 text-sm" style={{direction:'rtl'}} rows={2} value={form.description_ur} onChange={e => setForm({...form, description_ur: e.target.value})} />
            </div>
            <div>
              <label className="block text-xs font-medium text-gray-500 mb-1">Banner URL (English)</label>
              <input className="w-full border rounded-lg px-3 py-2 text-sm" value={form.banner_url} onChange={e => setForm({...form, banner_url: e.target.value})} />
            </div>
            <div>
              <label className="block text-xs font-medium text-gray-500 mb-1">Banner URL (Urdu)</label>
              <input className="w-full border rounded-lg px-3 py-2 text-sm" value={form.banner_url_ur} onChange={e => setForm({...form, banner_url_ur: e.target.value})} />
            </div>
          </div>
          <button type="submit" className="bg-red-900 text-white px-6 py-2 rounded-lg text-sm font-medium hover:bg-red-800">Create Promotion</button>
        </form>
      )}

      {isLoading ? (
        <p className="text-gray-500">Loading...</p>
      ) : (
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 border-b">
              <tr>
                <th className="text-left p-3 text-xs font-medium text-gray-500 uppercase">Code</th>
                <th className="text-left p-3 text-xs font-medium text-gray-500 uppercase">Discount</th>
                <th className="text-left p-3 text-xs font-medium text-gray-500 uppercase">Min Order</th>
                <th className="text-left p-3 text-xs font-medium text-gray-500 uppercase">Used</th>
                <th className="text-left p-3 text-xs font-medium text-gray-500 uppercase">Max Uses</th>
                <th className="text-left p-3 text-xs font-medium text-gray-500 uppercase">Status</th>
                <th className="text-left p-3 text-xs font-medium text-gray-500 uppercase">Actions</th>
              </tr>
            </thead>
            <tbody>
              {data?.data?.length === 0 ? (
                <tr><td colSpan={7} className="p-6 text-center text-gray-400 text-sm">No promotions yet</td></tr>
              ) : data?.data?.map((p: any) => (
                <tr key={p.id} className="border-b last:border-0 hover:bg-gray-50">
                  <td className="p-3 text-sm font-mono font-medium">{p.code}</td>
                  <td className="p-3 text-sm">{p.discount_type === 'percentage' ? `${p.discount_value}%` : `Rs. ${p.discount_value}`}</td>
                  <td className="p-3 text-sm">Rs. {p.min_order_amount || 0}</td>
                  <td className="p-3 text-sm">{p.current_uses || 0}</td>
                  <td className="p-3 text-sm">{p.max_uses || '∞'}</td>
                  <td className="p-3">
                    <span className={`px-2 py-1 rounded-full text-xs ${p.is_active ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}>
                      {p.is_active ? 'Active' : 'Inactive'}
                    </span>
                  </td>
                  <td className="p-3">
                    <span className="text-xs text-gray-400">{p.created_at ? new Date(p.created_at).toLocaleDateString() : ''}</span>
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
