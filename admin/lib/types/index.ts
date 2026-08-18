export interface DashboardStats {
  today_orders: number;
  today_revenue: number;
  total_customers: number;
  pending_orders: number;
}

export interface Order {
  id: string;
  order_number: string;
  status: OrderStatus;
  subtotal: number;
  delivery_fee: number;
  discount: number;
  total: number;
  payment_method: string;
  user_id: string;
  rider_id: string | null;
  created_at: string;
  items: OrderItem[];
}

export type OrderStatus =
  | 'pending'
  | 'confirmed'
  | 'preparing'
  | 'cutting'
  | 'packed'
  | 'rider_assigned'
  | 'out_for_delivery'
  | 'delivered'
  | 'cancelled';

export interface OrderItem {
  id: string;
  product_name: string;
  weight_kg: number;
  cut_type: string;
  subtotal: number;
}

export interface Product {
  id: string;
  name: string;
  slug: string;
  category_id: string;
  price_per_kg: number;
  stock_kg: number;
  is_active: boolean;
  images: string[];
  freshness_status: string;
}

export interface Customer {
  id: string;
  name: string | null;
  phone: string;
  email: string | null;
  total_orders?: number;
  total_spent?: number;
  created_at: string;
}

export interface Review {
  id: string;
  order_id: string;
  user_id: string;
  product_id: string;
  rating: number;
  comment: string | null;
  is_approved: boolean;
  created_at: string;
}

export interface Promotion {
  id: string;
  code: string;
  discount_type: 'percentage' | 'fixed';
  discount_value: number;
  min_order_amount: number;
  max_uses: number | null;
  current_uses: number;
  is_active: boolean;
  expires_at: string | null;
}

export interface SalesDataPoint {
  date: string;
  orders: number;
  revenue: number;
}

export interface TopProduct {
  product_name: string;
  total_kg: number;
  total_sales: number;
  order_count: number;
}
