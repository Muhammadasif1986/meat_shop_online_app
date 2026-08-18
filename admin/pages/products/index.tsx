'use client';

import { useState } from 'react';
import DashboardLayout from '@/components/layout/DashboardLayout';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { productsApi, categoriesApi } from '@/lib/api/endpoints';
import { useTranslation } from '@/lib/i18n/context';
import toast from 'react-hot-toast';

const cutOptionsList = ['curry_cut', 'bbq_cut', 'boneless', 'mince', 'custom'];

export default function ProductsPage() {
  const { t, locale } = useTranslation();
  const queryClient = useQueryClient();
  const [showForm, setShowForm] = useState(false);
  const [editId, setEditId] = useState<string | null>(null);
  const [form, setForm] = useState<any>({
    name: '', name_ur: '', category_id: '', price_per_kg: '', stock_kg: '',
    description: '', description_ur: '', min_order_kg: 0.5, max_order_kg: 5,
    cut_options: '[]', is_featured: false,
  });

  const { data: products, isLoading } = useQuery({
    queryKey: ['admin-products'],
    queryFn: () => productsApi.list().then(r => r.data),
  });

  const { data: cats, error: catsError } = useQuery({
    queryKey: ['admin-categories'],
    queryFn: () => categoriesApi.list().then(r => r.data),
  });
  if (catsError) console.error('Categories query error:', catsError);

  const createMut = useMutation({
    mutationFn: (d: any) => productsApi.create(d),
    onSuccess: () => { queryClient.invalidateQueries({ queryKey: ['admin-products'] }); setShowForm(false); resetForm(); toast.success('Product created'); },
    onError: (err: any) => {
      console.error('Product create error:', err?.response?.data || err);
      const detail = err?.response?.data?.detail;
      const msg = Array.isArray(detail) ? detail[0]?.msg : detail;
      toast.error(msg || 'Failed to create product');
    },
  });
  const updateMut = useMutation({
    mutationFn: ({ id, d }: { id: string; d: any }) => productsApi.update(id, d),
    onSuccess: () => { queryClient.invalidateQueries({ queryKey: ['admin-products'] }); setEditId(null); resetForm(); toast.success('Product updated'); },
    onError: (err: any) => {
      console.error('Product update error:', err?.response?.data || err);
      const detail = err?.response?.data?.detail;
      const msg = Array.isArray(detail) ? detail[0]?.msg : detail;
      toast.error(msg || 'Failed to update product');
    },
  });
  const stockMut = useMutation({
    mutationFn: ({ id, stock }: { id: string; stock: number }) => productsApi.updateStock(id, stock),
    onSuccess: () => { queryClient.invalidateQueries({ queryKey: ['admin-products'] }); toast.success('Stock updated'); },
    onError: (err: any) => {
      console.error('Stock update error:', err?.response?.data || err);
      const detail = err?.response?.data?.detail;
      const msg = Array.isArray(detail) ? detail[0]?.msg : detail;
      toast.error(msg || 'Failed to update stock');
    },
  });
  const deleteMut = useMutation({
    mutationFn: (id: string) => productsApi.delete(id),
    onSuccess: () => { queryClient.invalidateQueries({ queryKey: ['admin-products'] }); toast.success('Product deleted'); },
    onError: (err: any) => {
      console.error('Product delete error:', err?.response?.data || err);
      const detail = err?.response?.data?.detail;
      const msg = Array.isArray(detail) ? detail[0]?.msg : detail;
      toast.error(msg || 'Failed to delete product');
    },
  });

  function handleDelete(product: any) {
    if (!window.confirm(`Delete "${product.name}"? This cannot be undone.`)) return;
    deleteMut.mutate(product.id);
  }

  function resetForm() {
    setForm({ name: '', name_ur: '', category_id: '', price_per_kg: '', stock_kg: '',
      description: '', description_ur: '', min_order_kg: 0.5, max_order_kg: 5,
      cut_options: '[]', is_featured: false });
  }

  function openEdit(p: any) {
    setEditId(p.id);
    setForm({
      name: p.name, name_ur: p.name_ur || '', category_id: p.category_id,
      price_per_kg: String(p.price_per_kg), stock_kg: String(p.stock_kg || 0),
      description: p.description || '', description_ur: p.description_ur || '',
      min_order_kg: p.min_order_kg, max_order_kg: p.max_order_kg,
      cut_options: JSON.stringify(p.cut_options || []), is_featured: p.is_featured,
    });
  }

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    const payload = { ...form, price_per_kg: Number(form.price_per_kg), stock_kg: Number(form.stock_kg) };
    if (editId) updateMut.mutate({ id: editId, d: payload });
    else createMut.mutate(payload);
  }

  function handleStockUpdate(product: any) {
    const val = prompt('Enter stock (kg):', String(product.stock_kg || 0));
    if (val && !isNaN(Number(val))) stockMut.mutate({ id: product.id, stock: Number(val) });
  }

  const catMap: Record<string, string> = {};
  if (cats?.data) cats.data.forEach((c: any) => { catMap[c.id] = locale === 'ur' && c.name_ur ? c.name_ur : c.name; });

  return (
    <DashboardLayout>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold">Products</h1>
        <button onClick={() => { setShowForm(!showForm); setEditId(null); resetForm(); }}
          className="bg-red-900 text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-red-800">
          {showForm ? 'Cancel' : '+ Add Product'}
        </button>
      </div>

      {(showForm || editId) && (
        <form onSubmit={handleSubmit} className="bg-white rounded-xl p-6 shadow-sm border border-gray-100 mb-6">
          <h3 className="text-lg font-semibold mb-4">{editId ? 'Edit Product' : 'New Product'}</h3>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
            <div>
              <label className="block text-xs font-medium text-gray-500 mb-1">Name (English)</label>
              <input className="w-full border rounded-lg px-3 py-2 text-sm" value={form.name} onChange={e => setForm({...form, name: e.target.value})} required />
            </div>
            <div>
              <label className="block text-xs font-medium text-gray-500 mb-1">Name (Urdu)</label>
              <input className="w-full border rounded-lg px-3 py-2 text-sm" style={{direction:'rtl'}} value={form.name_ur} onChange={e => setForm({...form, name_ur: e.target.value})} />
            </div>
            <div>
              <label className="block text-xs font-medium text-gray-500 mb-1">Category</label>
              <select className="w-full border rounded-lg px-3 py-2 text-sm" value={form.category_id} onChange={e => setForm({...form, category_id: e.target.value})} required>
                <option value="">Select</option>
                {cats?.data?.map((c: any) => (
                  <option key={c.id} value={c.id}>{catMap[c.id] || c.name}</option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-xs font-medium text-gray-500 mb-1">Price (per kg)</label>
              <input type="number" step="0.1" className="w-full border rounded-lg px-3 py-2 text-sm" value={form.price_per_kg} onChange={e => setForm({...form, price_per_kg: e.target.value})} required />
            </div>
            <div>
              <label className="block text-xs font-medium text-gray-500 mb-1">Stock (kg)</label>
              <input type="number" step="0.1" className="w-full border rounded-lg px-3 py-2 text-sm" value={form.stock_kg} onChange={e => setForm({...form, stock_kg: e.target.value})} />
            </div>
            <div className="flex items-center gap-2 pt-6">
              <input type="checkbox" id="featured" checked={form.is_featured} onChange={e => setForm({...form, is_featured: e.target.checked})} />
              <label htmlFor="featured" className="text-sm">Featured</label>
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
              <label className="block text-xs font-medium text-gray-500 mb-1">Cut Options</label>
              <div className="flex flex-wrap gap-2">
                {cutOptionsList.map(co => (
                  <label key={co} className="flex items-center gap-1 text-sm">
                    <input type="checkbox" checked={form.cut_options.includes(co)} onChange={() => {
                      const current: string[] = JSON.parse(form.cut_options || '[]');
                      const next = current.includes(co) ? current.filter((x: string) => x !== co) : [...current, co];
                      setForm({...form, cut_options: JSON.stringify(next)});
                    }} /> {co.replace(/_/g, ' ')}
                  </label>
                ))}
              </div>
            </div>
          </div>
          <button type="submit" className="bg-red-900 text-white px-6 py-2 rounded-lg text-sm font-medium hover:bg-red-800">
            {editId ? 'Update' : 'Create'} Product
          </button>
        </form>
      )}

      {isLoading ? (
        <p className="text-gray-500">Loading...</p>
      ) : (
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 border-b">
              <tr>
                <th className="text-left p-3 text-xs font-medium text-gray-500 uppercase">Name</th>
                <th className="text-left p-3 text-xs font-medium text-gray-500 uppercase">Name (Ur)</th>
                <th className="text-left p-3 text-xs font-medium text-gray-500 uppercase">Category</th>
                <th className="text-left p-3 text-xs font-medium text-gray-500 uppercase">Price/kg</th>
                <th className="text-left p-3 text-xs font-medium text-gray-500 uppercase">Stock</th>
                <th className="text-left p-3 text-xs font-medium text-gray-500 uppercase">Status</th>
                <th className="text-left p-3 text-xs font-medium text-gray-500 uppercase">Actions</th>
              </tr>
            </thead>
            <tbody>
              {products?.data?.map((p: any) => (
                <tr key={p.id} className="border-b last:border-0 hover:bg-gray-50">
                  <td className="p-3 text-sm font-medium">{p.name}</td>
                  <td className="p-3 text-sm" style={{direction:'rtl'}}>{p.name_ur || '-'}</td>
                  <td className="p-3 text-sm">{catMap[p.category_id] || p.category_id?.slice(0, 8)}</td>
                  <td className="p-3 text-sm">Rs. {p.price_per_kg}</td>
                  <td className="p-3 text-sm">
                    <button onClick={() => handleStockUpdate(p)} className="hover:underline">{p.stock_kg ?? 0} kg</button>
                  </td>
                  <td className="p-3 text-sm">
                    <span className={`px-2 py-1 rounded-full text-xs ${p.is_active ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}>
                      {p.is_active ? 'Active' : 'Inactive'}
                    </span>
                  </td>
                  <td className="p-3">
                    <div className="flex items-center gap-3">
                      <button onClick={() => openEdit(p)} className="text-red-900 text-sm hover:underline">Edit</button>
                      <button onClick={() => handleDelete(p)} className="text-red-600 text-sm hover:underline">Delete</button>
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
