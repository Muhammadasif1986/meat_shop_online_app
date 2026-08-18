'use client';

import { useState, useEffect } from 'react';
import DashboardLayout from '@/components/layout/DashboardLayout';
import { useTranslation } from '@/lib/i18n/context';
import { adminApi } from '@/lib/api/endpoints';
import toast from 'react-hot-toast';

type Tab = 'products' | 'categories' | 'promotions';

interface TranslationRow {
  id: string;
  name_en: string;
  name_ur: string;
  description_en: string;
  description_ur: string;
  slug?: string;
  code?: string;
  banner_url?: string;
  banner_url_ur?: string;
}

export default function TranslationsPage() {
  const { t, locale } = useTranslation();
  const [tab, setTab] = useState<Tab>('products');
  const [data, setData] = useState<TranslationRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [editId, setEditId] = useState<string | null>(null);
  const [form, setForm] = useState<TranslationRow>({} as TranslationRow);

  const tabs: { key: Tab; labelEn: string; labelUr: string }[] = [
    { key: 'products', labelEn: 'Products', labelUr: 'مصنوعات' },
    { key: 'categories', labelEn: 'Categories', labelUr: 'اقسام' },
    { key: 'promotions', labelEn: 'Promotions', labelUr: 'پروموشنز' },
  ];

  useEffect(() => {
    fetchTranslations();
  }, [tab]);

  async function fetchTranslations() {
    setLoading(true);
    try {
      const res = await adminApi.getTranslations(tab);
      setData(res.data.data || []);
    } catch {
      toast.error('Failed to load translations');
    } finally {
      setLoading(false);
    }
  }

  function startEdit(row: TranslationRow) {
    setEditId(row.id);
    setForm({ ...row });
  }

  function cancelEdit() {
    setEditId(null);
    setForm({} as TranslationRow);
  }

  async function saveTranslation() {
    if (!editId) return;
    try {
      await adminApi.updateTranslation(tab, editId, form);
      toast.success(t('translations.updated'));
      setEditId(null);
      fetchTranslations();
    } catch {
      toast.error('Failed to update');
    }
  }

  function renderField(row: TranslationRow, field: keyof TranslationRow) {
    if (editId === row.id) {
      return (
        <input
          className="w-full border rounded px-2 py-1 text-sm"
          value={form[field] || ''}
          onChange={(e) => setForm({ ...form, [field]: e.target.value })}
        />
      );
    }
    return <span className="text-sm">{row[field] || '-'}</span>;
  }

  return (
    <DashboardLayout>
      <div className="mb-6">
        <h1 className="text-2xl font-bold mb-4">{t('translations.title')}</h1>
        <div className="flex gap-2">
          {tabs.map((tb) => (
            <button
              key={tb.key}
              onClick={() => { setTab(tb.key); setEditId(null); }}
              className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                tab === tb.key
                  ? 'bg-red-900 text-white'
                  : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
              }`}
            >
              {locale === 'ur' ? tb.labelUr : tb.labelEn}
            </button>
          ))}
        </div>
      </div>

      {loading ? (
        <p className="text-gray-500">{t('common.loading')}</p>
      ) : data.length === 0 ? (
        <p className="text-gray-500">{t('common.no_data')}</p>
      ) : (
        <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 border-b">
              <tr>
                <th className="text-left p-3 text-xs font-medium text-gray-500 uppercase">{t('translations.name_en')}</th>
                <th className="text-left p-3 text-xs font-medium text-gray-500 uppercase">{t('translations.name_ur')}</th>
                <th className="text-left p-3 text-xs font-medium text-gray-500 uppercase">{t('translations.desc_en')}</th>
                <th className="text-left p-3 text-xs font-medium text-gray-500 uppercase">{t('translations.desc_ur')}</th>
                {tab === 'promotions' && (
                  <>
                    <th className="text-left p-3 text-xs font-medium text-gray-500 uppercase">{t('translations.banner_en')}</th>
                    <th className="text-left p-3 text-xs font-medium text-gray-500 uppercase">{t('translations.banner_ur')}</th>
                  </>
                )}
                <th className="text-left p-3 text-xs font-medium text-gray-500 uppercase">{t('common.actions')}</th>
              </tr>
            </thead>
            <tbody>
              {data.map((row) => (
                <tr key={row.id} className="border-b last:border-0 hover:bg-gray-50">
                  <td className="p-3">{renderField(row, 'name_en')}</td>
                  <td className="p-3" style={{ direction: 'rtl' }}>{renderField(row, 'name_ur')}</td>
                  <td className="p-3">{renderField(row, 'description_en')}</td>
                  <td className="p-3" style={{ direction: 'rtl' }}>{renderField(row, 'description_ur')}</td>
                  {tab === 'promotions' && (
                    <>
                      <td className="p-3">{renderField(row, 'banner_url')}</td>
                      <td className="p-3" style={{ direction: 'rtl' }}>{renderField(row, 'banner_url_ur')}</td>
                    </>
                  )}
                  <td className="p-3">
                    {editId === row.id ? (
                      <div className="flex gap-2">
                        <button onClick={saveTranslation} className="px-3 py-1 bg-red-900 text-white rounded text-xs font-medium hover:bg-red-800">
                          {t('common.save')}
                        </button>
                        <button onClick={cancelEdit} className="px-3 py-1 bg-gray-200 text-gray-700 rounded text-xs font-medium hover:bg-gray-300">
                          {t('common.cancel')}
                        </button>
                      </div>
                    ) : (
                      <button onClick={() => startEdit(row)} className="px-3 py-1 bg-gray-100 text-gray-700 rounded text-xs font-medium hover:bg-gray-200">
                        {t('common.edit')}
                      </button>
                    )}
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
