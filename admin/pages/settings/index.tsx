'use client';

import { useState } from 'react';
import DashboardLayout from '@/components/layout/DashboardLayout';
import { useTranslation } from '@/lib/i18n/context';
import { useAuthStore } from '@/lib/store/auth-store';
import { Globe, Bell, Shield, Info } from 'lucide-react';
import toast from 'react-hot-toast';
import { apiClient } from '@/lib/api/client';

export default function SettingsPage() {
  const { t, locale, setLocale } = useTranslation();
  const { user, token } = useAuthStore();
  const [saving, setSaving] = useState(false);

  async function updateLang(lang: string) {
    setSaving(true);
    setLocale(lang);
    try {
      await apiClient.patch('/auth/me', { language_pref: lang });
      toast.success('Language updated');
    } catch {
      // still works locally even if API fails
    } finally {
      setSaving(false);
    }
  }

  return (
    <DashboardLayout>
      <h1 className="text-xl sm:text-2xl font-bold mb-6">Settings</h1>

      <div className="space-y-6 max-w-2xl">
        {/* Language */}
        <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
          <div className="flex items-center gap-3 mb-4">
            <Globe size={20} className="text-red-900" />
            <h3 className="font-semibold">Language / زبان</h3>
          </div>
          <div className="flex gap-3">
            <button
              onClick={() => updateLang('en')}
              className={`px-6 py-3 rounded-lg border text-sm font-medium transition-colors ${
                locale === 'en' ? 'bg-red-900 text-white border-red-900' : 'bg-white text-gray-600 border-gray-200 hover:border-gray-300'
              }`}
            >
              English
            </button>
            <button
              onClick={() => updateLang('ur')}
              className={`px-6 py-3 rounded-lg border text-sm font-medium transition-colors ${
                locale === 'ur' ? 'bg-red-900 text-white border-red-900' : 'bg-white text-gray-600 border-gray-200 hover:border-gray-300'
              }`}
            >
              اردو
            </button>
          </div>
        </div>

        {/* Profile */}
        <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
          <div className="flex items-center gap-3 mb-4">
            <Shield size={20} className="text-red-900" />
            <h3 className="font-semibold">Profile</h3>
          </div>
          <div className="space-y-3 text-sm">
            <div className="flex justify-between py-2 border-b border-gray-50">
              <span className="text-gray-500">Name</span>
              <span className="font-medium">{user?.name || '—'}</span>
            </div>
            <div className="flex justify-between py-2 border-b border-gray-50">
              <span className="text-gray-500">Email</span>
              <span className="font-medium">{user?.email || '—'}</span>
            </div>
            <div className="flex justify-between py-2 border-b border-gray-50">
              <span className="text-gray-500">Role</span>
              <span className="font-medium capitalize">{user?.role || '—'}</span>
            </div>
          </div>
        </div>

        {/* Notifications */}
        <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
          <div className="flex items-center gap-3 mb-4">
            <Bell size={20} className="text-red-900" />
            <h3 className="font-semibold">Notifications</h3>
          </div>
          <p className="text-sm text-gray-500">Notification preferences will be available in the next update.</p>
        </div>

        {/* About */}
        <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
          <div className="flex items-center gap-3 mb-4">
            <Info size={20} className="text-red-900" />
            <h3 className="font-semibold">About</h3>
          </div>
          <div className="space-y-2 text-sm text-gray-500">
            <p>Abdul Ghaffar Meat Shop — Admin Panel v1.0.0</p>
            <p>Fresh halal meat delivery for Naval Colony, Karachi.</p>
          </div>
        </div>
      </div>
    </DashboardLayout>
  );
}
