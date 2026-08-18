# API Specification — Abdul Ghaffar Meat Shop

**Base URL:** `https://api.abdulghaffarmeatshop.com/api/v1`  
**Auth:** Bearer JWT token in `Authorization` header  
**Response Envelope:**

```json
{
  "success": true,
  "data": { ... },
  "message": "Success",
  "meta": {
    "page": 1,
    "per_page": 20,
    "total": 100,
    "total_pages": 5
  }
}
```

---

## AUTHENTICATION

### POST /auth/send-otp
Send OTP to phone number.
```json
// Request
{ "phone": "+923001234567" }
// Response 200
{ "success": true, "message": "OTP sent", "data": { "expires_in": 300 } }
```

### POST /auth/verify-otp
Verify OTP and receive JWT.
```json
// Request
{ "phone": "+923001234567", "otp": "123456" }
// Response 200
{
  "success": true,
  "data": {
    "access_token": "eyJ...",
    "refresh_token": "eyJ...",
    "expires_in": 3600,
    "user": { "id": "uuid", "name": null, "phone": "+923001234567", "role": "customer" }
  }
}
```

### POST /auth/refresh
Refresh access token.
```json
// Request
{ "refresh_token": "eyJ..." }
// Response 200
{ "success": true, "data": { "access_token": "eyJ...", "expires_in": 3600 } }
```

### POST /auth/logout
Invalidate tokens.

---

## USERS

### GET /users/me
Get current user profile.

### PATCH /users/me
Update profile.
```json
{ "name": "Ahmed Khan", "email": "ahmed@email.com", "avatar_url": "..." }
```

---

## ADDRESSES

### GET /addresses
List user addresses.

### POST /addresses
```json
{
  "label": "Home",
  "full_address": "House 12, Street 5, Naval Colony",
  "street": "Street 5",
  "sector": "Sector B",
  "house_no": "12",
  "landmark": "Near Masjid",
  "latitude": 24.8607,
  "longitude": 67.0011,
  "is_default": true
}
```

### PATCH /addresses/{id}
### DELETE /addresses/{id}

---

## PRODUCTS

### GET /products
Query params: `?category=beef&search=&min_price=&max_price=&sort=popularity&page=1&per_page=20`

### GET /products/{slug}
Detailed product with cut options and stock info.

### GET /products/featured
Featured products for homepage.

### GET /categories
List all categories.

---

## FRESHNESS

### GET /freshness
```json
{
  "success": true,
  "data": [
    {
      "category": "chicken",
      "arrival_time": "07:00",
      "message": "Fresh Chicken Arrived at 7:00 AM",
      "is_today": true,
      "next_arrival_in": null
    }
  ]
}
```

---

## CART

### GET /cart
Get current user's cart with items.

### POST /cart/items
Add item to cart.
```json
{
  "product_id": "uuid",
  "weight_kg": 1.0,
  "cut_type": "curry_cut",
  "custom_instructions": "Cut into small pieces"
}
```

### PATCH /cart/items/{item_id}
Update item weight or cut.

### DELETE /cart/items/{item_id}
Remove item from cart.

### DELETE /cart
Clear cart.

### POST /cart/apply-promo
```json
{ "code": "WELCOME10" }
```

### DELETE /cart/remove-promo

---

## ORDERS

### POST /orders
Place order from cart.
```json
{
  "address_id": "uuid",
  "delivery_notes": "Call before delivery",
  "is_asap": true,
  "scheduled_date": "2026-06-16",
  "scheduled_slot": "10:00-11:00",
  "payment_method": "cod"
}
```
Response includes `order_number` and current status.

### GET /orders
List user's orders (paginated, sorted by date desc).

### GET /orders/{id}
Full order details with items, status log, and rider info.

### POST /orders/{id}/cancel
```json
{ "reason": "Changed my mind" }
```

### POST /orders/{id}/reorder
Create a new order with same items.

---

## ORDER TRACKING

### GET /orders/{id}/track
Real-time tracking data:
```json
{
  "status": "out_for_delivery",
  "estimated_delivery": "2026-06-15T11:30:00Z",
  "current_slot": 5,
  "total_slots": 7,
  "statuses": [
    { "status": "pending", "timestamp": "...", "label": "Order Received" },
    { "status": "confirmed", "timestamp": "...", "label": "Order Confirmed" },
    { "status": "preparing", "timestamp": "...", "label": "Preparing" },
    { "status": "cutting", "timestamp": "...", "label": "Cutting Meat" },
    { "status": "packed", "timestamp": "...", "label": "Packed" },
    { "status": "rider_assigned", "timestamp": "...", "label": "Rider Assigned" },
    { "status": "out_for_delivery", "timestamp": "...", "label": "Out for Delivery" }
  ],
  "rider": {
    "name": "Ali Raza",
    "phone": "+923001112233"
  }
}
```

---

## REVIEWS

### POST /reviews
```json
{
  "order_id": "uuid",
  "product_id": "uuid",
  "rating": 5,
  "comment": "Excellent quality meat!",
  "images": ["url1", "url2"]
}
```

### GET /reviews?product_id=uuid
Get reviews for a product.

---

## SUBSCRIPTIONS

### POST /subscriptions
```json
{
  "plan_name": "Weekly Chicken",
  "interval_type": "weekly",
  "total_cycles": 4,
  "items": [
    { "product_id": "uuid", "weight_kg": 2.0, "cut_type": "curry_cut" }
  ],
  "delivery_slot": "10:00-11:00",
  "address_id": "uuid",
  "start_date": "2026-06-20"
}
```

### GET /subscriptions
List user's subscriptions.

### PATCH /subscriptions/{id}
Pause/resume/cancel.

---

## NOTIFICATIONS

### GET /notifications
Paginated list.

### PATCH /notifications/{id}/read
Mark as read.

### POST /notifications/read-all

---

## PROMOTIONS

### GET /promotions/active
Active promo codes and banners.

---

## ADMIN API

All admin endpoints prefixed with `/admin` and require `admin` or `superadmin` role.

### GET /admin/dashboard/stats
Daily, weekly, monthly sales, top products, customer count, order trends.

### GET /admin/orders
All orders with filters: status, date range, customer.

### PATCH /admin/orders/{id}/status
Update order status.
```json
{ "status": "preparing", "notes": "Starting preparation" }
```

### POST /admin/orders/{id}/assign-rider
```json
{ "rider_id": "uuid" }
```

### GET /admin/orders/{id}/invoice
Generate printable invoice.

### CRUD /admin/products
Full CRUD for product management.

### CRUD /admin/categories
Category management.

### PATCH /admin/products/{id}/stock
```json
{ "stock_kg": 50.0 }
```

### GET /admin/reviews
List all reviews, approve/delete.

### CRUD /admin/promotions
Promo code management.

### GET /admin/customers
Customer list with order history.

### GET /admin/analytics/*
Sales, revenue, growth, trends.

---

## RIDER API

All rider endpoints prefixed with `/rider` and require `rider` role.

### GET /rider/orders
Assigned orders.

### PATCH /rider/orders/{id}/status
```json
{ "status": "picked_up" }
```

### PATCH /rider/orders/{id}/confirm-delivery

---

## ERROR CODES

| Code | Message | HTTP Status |
|------|---------|-------------|
| AUTH_001 | Invalid OTP | 401 |
| AUTH_002 | OTP Expired | 401 |
| AUTH_003 | Token Expired | 401 |
| AUTH_004 | Invalid Token | 401 |
| CART_001 | Cart Empty | 400 |
| CART_002 | Item Not Found | 404 |
| ORD_001 | Invalid Address | 400 |
| ORD_002 | Outside Service Area | 400 |
| ORD_003 | Order Cannot Be Cancelled | 400 |
| ORD_004 | Invalid Status Transition | 400 |
| PROD_001 | Insufficient Stock | 400 |
| PROMO_001 | Invalid Code | 400 |
| PROMO_002 | Code Expired | 400 |
| PROMO_003 | Usage Limit Reached | 400 |
| GEN_001 | Internal Server Error | 500 |
