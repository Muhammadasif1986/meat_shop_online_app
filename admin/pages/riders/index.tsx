'use client';

import { useState } from 'react';
import DashboardLayout from '@/components/layout/DashboardLayout';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { ridersApi } from '@/lib/api/endpoints';
import { Truck, UserPlus, Trash2 } from 'lucide-react';
import toast from 'react-hot-toast';

export default function RidersPage() {
  const queryClient = useQueryClient();
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({ name: '', phone: '', email: '' });

  const { data, isLoading } = useQuery({
    queryKey: ['admin-riders'],
    queryFn: () => ridersApi.list().then(r => r.data),
  });

  const createMut = useMutation({
    mutationFn: (d: any) => ridersApi.create(d),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-riders'] });
      setShowForm(false); setForm({ name: '', phone: '', email: '' });
      toast.success('Rider added');
    },
    onError: (err: any) => {
      console.error('Rider creation error:', err?.response?.data || err);
      const detail = err?.response?.data?.detail;
      const msg = Array.isArray(detail) ? detail[0]?.msg : detail;
      toast.error(msg || err?.response?.data?.message || 'Failed to add rider');
    },
  });

  const toggleMut = useMutation({
    mutationFn: (id: string) => ridersApi.toggleActive(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-riders'] });
      toast.success('Rider status updated');
    },
    onError: (err: any) => {
      console.error('Toggle rider error:', err?.response?.data || err);
      const detail = err?.response?.data?.detail;
      const msg = Array.isArray(detail) ? detail[0]?.msg : detail;
      toast.error(msg || 'Failed to update rider status');
    },
  });

  const deleteMut = useMutation({
    mutationFn: (id: string) => ridersApi.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-riders'] });
      toast.success('Rider deleted');
    },
    onError: (err: any) => {
      console.error('Delete rider error:', err?.response?.data || err);
      const detail = err?.response?.data?.detail;
      const msg = Array.isArray(detail) ? detail[0]?.msg : detail;
      toast.error(msg || 'Failed to delete rider');
    },
  });

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    createMut.mutate(form);
  }

  return (
    <DashboardLayout>
      <div className="flex flex-wrap items-center justify-between mb-6 gap-3">
        <h1 className="text-xl sm:text-2xl font-bold">Riders</h1>
        <button onClick={() => setShowForm(!showForm)}
          className="bg-red-900 text-white px-3 sm:px-4 py-2 rounded-lg text-sm font-medium hover:bg-red-800 flex items-center gap-2 whitespace-nowrap">
          <UserPlus size={16} /> {showForm ? 'Cancel' : 'Add Rider'}
        </button>
      </div>

      {showForm && (
        <form onSubmit={handleSubmit} className="bg-white rounded-xl p-6 shadow-sm border border-gray-100 mb-6">
          <h3 className="text-lg font-semibold mb-4">New Rider</h3>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
            <div>
              <label className="block text-xs font-medium text-gray-500 mb-1">Name</label>
              <input className="w-full border rounded-lg px-3 py-2 text-sm" value={form.name} onChange={e => setForm({...form, name: e.target.value})} required />
            </div>
            <div>
              <label className="block text-xs font-medium text-gray-500 mb-1">Phone</label>
              <input className="w-full border rounded-lg px-3 py-2 text-sm" value={form.phone} onChange={e => setForm({...form, phone: e.target.value})} required placeholder="+923001234567" />
            </div>
            <div>
              <label className="block text-xs font-medium text-gray-500 mb-1">Email</label>
              <input type="email" className="w-full border rounded-lg px-3 py-2 text-sm" value={form.email} onChange={e => setForm({...form, email: e.target.value})} />
            </div>
          </div>
          <button type="submit" className="bg-red-900 text-white px-6 py-2 rounded-lg text-sm font-medium hover:bg-red-800">Add Rider</button>
        </form>
      )}

      {isLoading ? (
        <p className="text-gray-500">Loading...</p>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {data?.data?.length === 0 ? (
            <div className="col-span-full bg-white rounded-xl p-6 shadow-sm border border-gray-100 text-center text-gray-400 text-sm">No riders yet</div>
          ) : data?.data?.map((r: any) => (
            <div key={r.id} className="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
              <div className="flex items-start justify-between">
                <div className="flex items-center gap-3">
                  <div className="p-3 bg-red-50 rounded-lg">
                    <Truck size={24} className="text-red-900" />
                  </div>
                  <div>
                    <p className="font-medium text-sm">{r.name || 'Unnamed'}</p>
                    <p className="text-xs text-gray-500">{r.phone}</p>
                    {r.email && <p className="text-xs text-gray-400">{r.email}</p>}
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <button
                    onClick={() => toggleMut.mutate(r.id)}
                    className={`px-2 py-1 rounded-full text-xs font-medium ${r.is_active ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}
                  >
                    {r.is_active ? 'Active' : 'Inactive'}
                  </button>
                  <button
                    onClick={() => { if (confirm('Delete rider?')) deleteMut.mutate(r.id); }}
                    className="p-1.5 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                    title="Delete rider"
                  >
                    <Trash2 size={16} />
                  </button>
                </div>
              </div>
              <div className="mt-3 pt-3 border-t border-gray-100 text-xs text-gray-400">
                Joined: {new Date(r.created_at).toLocaleDateString()}
              </div>
            </div>
          ))}
        </div>
      )}
    </DashboardLayout>
  );
}
