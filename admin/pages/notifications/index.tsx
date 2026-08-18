'use client';

import { useState } from 'react';
import DashboardLayout from '@/components/layout/DashboardLayout';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { notificationsApi } from '@/lib/api/endpoints';
import { Bell, Send } from 'lucide-react';
import toast from 'react-hot-toast';

export default function NotificationsPage() {
  const queryClient = useQueryClient();
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({
    title: '', title_ur: '', body: '', body_ur: '', user_id: '',
  });

  const { data, isLoading } = useQuery({
    queryKey: ['admin-notifications'],
    queryFn: () => notificationsApi.list().then(r => r.data),
  });

  const sendMut = useMutation({
    mutationFn: (d: any) => notificationsApi.send(d),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-notifications'] });
      setShowForm(false);
      setForm({ title: '', title_ur: '', body: '', body_ur: '', user_id: '' });
      toast.success('Notification sent');
    },
    onError: (err: any) => toast.error(err?.response?.data?.detail || err?.response?.data?.message || 'Failed to send notification'),
  });

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    const payload: any = { title: form.title, body: form.body };
    if (form.title_ur) payload.title_ur = form.title_ur;
    if (form.body_ur) payload.body_ur = form.body_ur;
    if (form.user_id) payload.user_id = form.user_id;
    sendMut.mutate(payload);
  }

  return (
    <DashboardLayout>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold">Notifications</h1>
        <button onClick={() => setShowForm(!showForm)}
          className="bg-red-900 text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-red-800 flex items-center gap-2">
          <Send size={16} /> {showForm ? 'Cancel' : 'Send Notification'}
        </button>
      </div>

      {showForm && (
        <form onSubmit={handleSubmit} className="bg-white rounded-xl p-6 shadow-sm border border-gray-100 mb-6">
          <h3 className="text-lg font-semibold mb-4">Send Notification</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
            <div>
              <label className="block text-xs font-medium text-gray-500 mb-1">Title (English)</label>
              <input className="w-full border rounded-lg px-3 py-2 text-sm" value={form.title} onChange={e => setForm({...form, title: e.target.value})} required />
            </div>
            <div>
              <label className="block text-xs font-medium text-gray-500 mb-1">Title (Urdu)</label>
              <input className="w-full border rounded-lg px-3 py-2 text-sm" style={{direction:'rtl'}} value={form.title_ur} onChange={e => setForm({...form, title_ur: e.target.value})} />
            </div>
            <div>
              <label className="block text-xs font-medium text-gray-500 mb-1">Body (English)</label>
              <textarea className="w-full border rounded-lg px-3 py-2 text-sm" rows={3} value={form.body} onChange={e => setForm({...form, body: e.target.value})} required />
            </div>
            <div>
              <label className="block text-xs font-medium text-gray-500 mb-1">Body (Urdu)</label>
              <textarea className="w-full border rounded-lg px-3 py-2 text-sm" style={{direction:'rtl'}} rows={3} value={form.body_ur} onChange={e => setForm({...form, body_ur: e.target.value})} />
            </div>
            <div className="md:col-span-2">
              <label className="block text-xs font-medium text-gray-500 mb-1">
                User ID (leave empty to send to all customers)
              </label>
              <input className="w-full border rounded-lg px-3 py-2 text-sm" value={form.user_id} onChange={e => setForm({...form, user_id: e.target.value})} placeholder="Send to all customers" />
            </div>
          </div>
          <button type="submit" className="bg-red-900 text-white px-6 py-2 rounded-lg text-sm font-medium hover:bg-red-800 flex items-center gap-2">
            <Send size={16} /> Send Notification
          </button>
        </form>
      )}

      {isLoading ? (
        <p className="text-gray-500">Loading...</p>
      ) : (
        <div className="space-y-3">
          {data?.data?.length === 0 ? (
            <div className="bg-white rounded-xl p-12 shadow-sm border border-gray-100 text-center">
              <Bell size={48} className="mx-auto text-gray-300 mb-4" />
              <p className="text-gray-400 text-sm">No notifications sent yet</p>
            </div>
          ) : data?.data?.map((n: any) => (
            <div key={n.id} className="bg-white rounded-xl p-4 shadow-sm border border-gray-100">
              <div className="flex items-start justify-between">
                <div className="flex-1">
                  <div className="flex items-center gap-2">
                    <h4 className="font-medium text-sm">{n.title}</h4>
                    {n.title_ur && <span className="text-sm text-gray-400" style={{direction:'rtl'}}>| {n.title_ur}</span>}
                    {!n.is_read && <span className="w-2 h-2 bg-red-500 rounded-full" />}
                  </div>
                  <p className="text-sm text-gray-600 mt-1">{n.body}</p>
                  <p className="text-xs text-gray-400 mt-1">
                    To: {n.user_id?.slice(0, 12)}... | Type: {n.type || 'admin'} | {new Date(n.sent_at).toLocaleString()}
                  </p>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </DashboardLayout>
  );
}
