'use client';

import { createContext, useContext, useState, useEffect, useCallback, ReactNode } from 'react';

const translations: Record<string, Record<string, string>> = {
  en: {
    'app.name': 'AG Meat Shop',
    'app.tagline': 'Admin Panel',
    'nav.dashboard': 'Dashboard',
    'nav.orders': 'Orders',
    'nav.products': 'Products',
    'nav.customers': 'Customers',
    'nav.analytics': 'Analytics',
    'nav.promotions': 'Promotions',
    'nav.reviews': 'Reviews',
    'nav.riders': 'Riders',
    'nav.subscriptions': 'Subscriptions',
    'nav.notifications': 'Notifications',
    'nav.settings': 'Settings',
    'nav.translations': 'Translations',
    'header.welcome': 'Welcome',
    'header.lang.en': 'English',
    'header.lang.ur': 'Urdu',
    'common.save': 'Save',
    'common.cancel': 'Cancel',
    'common.delete': 'Delete',
    'common.edit': 'Edit',
    'common.search': 'Search',
    'common.loading': 'Loading...',
    'common.no_data': 'No data found',
    'common.status': 'Status',
    'common.actions': 'Actions',
    'common.date': 'Date',
    'common.total': 'Total',
    'common.email': 'Email',
    'common.phone': 'Phone',
    'common.name': 'Name',
    'translations.title': 'Translations',
    'translations.products': 'Products',
    'translations.categories': 'Categories',
    'translations.promotions': 'Promotions & Banners',
    'translations.name_en': 'Name (English)',
    'translations.name_ur': 'Name (Urdu)',
    'translations.desc_en': 'Description (English)',
    'translations.desc_ur': 'Description (Urdu)',
    'translations.banner_en': 'Banner URL (English)',
    'translations.banner_ur': 'Banner URL (Urdu)',
    'translations.updated': 'Translation updated',
    'translations.select_tab': 'Select a tab to manage translations',
  },
  ur: {
    'app.name': 'اے جی گوشت کی دکان',
    'app.tagline': 'ایڈمن پینل',
    'nav.dashboard': 'ڈیش بورڈ',
    'nav.orders': 'آرڈرز',
    'nav.products': 'مصنوعات',
    'nav.customers': 'صارفین',
    'nav.analytics': 'تجزیہ',
    'nav.promotions': 'پروموشنز',
    'nav.reviews': 'جائزے',
    'nav.riders': 'رائیڈرز',
    'nav.subscriptions': 'سبسکرپشنز',
    'nav.notifications': 'اطلاعات',
    'nav.settings': 'سیٹنگز',
    'nav.translations': 'ترجمہ',
    'header.welcome': 'خوش آمدید',
    'header.lang.en': 'انگریزی',
    'header.lang.ur': 'اردو',
    'common.save': 'محفوظ کریں',
    'common.cancel': 'منسوخ کریں',
    'common.delete': 'حذف کریں',
    'common.edit': 'ترمیم',
    'common.search': 'تلاش',
    'common.loading': 'لوڈ ہو رہا ہے...',
    'common.no_data': 'کوئی ڈیٹا نہیں ملا',
    'common.status': 'حالت',
    'common.actions': 'کارروائیاں',
    'common.date': 'تاریخ',
    'common.total': 'کل',
    'common.email': 'ای میل',
    'common.phone': 'فون',
    'common.name': 'نام',
    'translations.title': 'ترجمہ',
    'translations.products': 'مصنوعات',
    'translations.categories': 'اقسام',
    'translations.promotions': 'پروموشنز اور بینرز',
    'translations.name_en': 'نام (انگریزی)',
    'translations.name_ur': 'نام (اردو)',
    'translations.desc_en': 'تفصیل (انگریزی)',
    'translations.desc_ur': 'تفصیل (اردو)',
    'translations.banner_en': 'بینر یو آر ایل (انگریزی)',
    'translations.banner_ur': 'بینر یو آر ایل (اردو)',
    'translations.updated': 'ترجمہ اپ ڈیٹ ہوگیا',
    'translations.select_tab': 'ترجمہ کے لیے ایک ٹیب منتخب کریں',
  },
};

interface LanguageContextValue {
  locale: string;
  setLocale: (l: string) => void;
  t: (key: string) => string;
  isRtl: boolean;
}

const LanguageContext = createContext<LanguageContextValue>({
  locale: 'en',
  setLocale: () => {},
  t: (k: string) => k,
  isRtl: false,
});

export function LanguageProvider({ children }: { children: ReactNode }) {
  const [locale, setLocaleState] = useState('en');

  useEffect(() => {
    const saved = localStorage.getItem('admin-locale');
    if (saved === 'ur' || saved === 'en') setLocaleState(saved);
  }, []);

  const setLocale = useCallback((l: string) => {
    setLocaleState(l);
    localStorage.setItem('admin-locale', l);
  }, []);

  const t = useCallback((key: string) => {
    return translations[locale]?.[key] || key;
  }, [locale]);

  const isRtl = locale === 'ur';

  return (
    <LanguageContext.Provider value={{ locale, setLocale, t, isRtl }}>
      <div dir={isRtl ? 'rtl' : 'ltr'} className={isRtl ? 'font-noto-nastaliq' : ''}>
        {children}
      </div>
    </LanguageContext.Provider>
  );
}

export function useTranslation() {
  return useContext(LanguageContext);
}
