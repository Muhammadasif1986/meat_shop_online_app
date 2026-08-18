# System Architecture — Abdul Ghaffar Meat Shop

## 1. High-Level Architecture

```
                                   ┌──────────────────────────┐
                                   │     Firebase Cloud       │
                                   │     Messaging (FCM)      │
                                   └──────────┬───────────────┘
                                              │ Push Notifications
                    ┌──────────────────────────┼──────────────────────────┐
                    │                          │                          │
                    ▼                          ▼                          ▼
          ┌──────────────────┐      ┌──────────────────┐      ┌──────────────────┐
          │   Flutter App    │      │   Admin Panel    │      │   Web (PWA)      │
          │   (Android)      │      │   (Next.js)      │      │   (Flutter Web)  │
          └────────┬─────────┘      └────────┬─────────┘      └────────┬─────────┘
                   │                         │                         │
                   ├──────────────┬──────────┼──────────┬──────────────┘
                   │              │          │          │
                   ▼              ▼          ▼          ▼
          ┌─────────────────────────────────────────────────────────────────┐
          │                      NGINX / Load Balancer                       │
          │           (SSL Termination, Rate Limiting, Reverse Proxy)        │
          └──────────────────────────────┬──────────────────────────────────┘
                                         │
                                         ▼
          ┌─────────────────────────────────────────────────────────────────┐
          │                     FastAPI Application                          │
          │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌───────────────────┐  │
          │  │ Auth     │ │ Products │ │ Orders   │ │ Admin             │  │
          │  │ Module   │ │ Module   │ │ Module   │ │ Module            │  │
          │  └──────────┘ └──────────┘ └──────────┘ └───────────────────┘  │
          │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌───────────────────┐  │
          │  │ Cart     │ │ Payments │ │ Subscrip │ │ Notifications     │  │
          │  │ Module   │ │ Module   │ │-tions    │ │ Module            │  │
          │  └──────────┘ └──────────┘ └──────────┘ └───────────────────┘  │
          └──────────────────────────────┬──────────────────────────────────┘
                                         │
                    ┌────────────────────┼────────────────────┐
                    │                    │                    │
                    ▼                    ▼                    ▼
          ┌──────────────┐    ┌──────────────┐    ┌──────────────────┐
          │  PostgreSQL  │    │    Redis     │    │   Celery Workers │
          │  (Primary)   │    │  (Cache/Q)   │    │  (Async Tasks)   │
          └──────────────┘    └──────────────┘    └──────────────────┘
                                                           │
                                                           ▼
                                                  ┌──────────────────┐
                                                  │   Cloudinary     │
                                                  │   (Images)       │
                                                  └──────────────────┘
```

## 2. Clean Architecture Layers (Per Module)

```
┌──────────────────────────────────────────────────────────────┐
│                    Presentation Layer                         │
│  (Flutter Screens / Next.js Pages / FastAPI Routes)          │
├──────────────────────────────────────────────────────────────┤
│                    Application Layer                          │
│  (Use Cases / Services / DTOs)                               │
├──────────────────────────────────────────────────────────────┤
│                    Domain Layer                               │
│  (Entities / Value Objects / Repository Interfaces)          │
├──────────────────────────────────────────────────────────────┤
│                    Infrastructure Layer                       │
│  (Database / External APIs / Cache / File Storage)           │
└──────────────────────────────────────────────────────────────┘
```

## 3. Data Flow

### Order Placement Flow
```
User → App → POST /orders → FastAPI:
  1. Validate cart (stock check, pricing)
  2. Apply promo if present
  3. Validate address (service area check)
  4. Create order (status: pending)
  5. Clear cart
  6. Deduct stock (optimistic)
  7. Send FCM notification to admin
  8. Push notification to user
  9. Enqueue Celery task for auto-cancellation (30 min)
```

### Delivery Tracking Flow
```
Rider → Rider App → PATCH /status → FastAPI:
  1. Validate status transition (PREPARING → CUTTING → PACKED → ...)
  2. Log status change in order_status_log
  3. Update order.status
  4. Push notification to user
  5. If delivered: update delivered_at, trigger review prompt
```

## 4. Design Patterns

| Pattern | Usage |
|---------|-------|
| Repository Pattern | Data access abstraction per entity |
| Service Layer | Business logic encapsulation |
| DTO Pattern | Request/response data shaping |
| Factory Pattern | Order creation, notification creation |
| Observer Pattern | Event-driven status updates |
| Strategy Pattern | Payment gateway, delivery fee calculation |
| Singleton | Database session, Redis client |
| Unit of Work | Transaction management for orders |
| Circuit Breaker | External API calls (SMS, payment) |

## 5. SOLID Principles Applied

- **S**: Each service class has one responsibility (e.g., `OrderService` handles only orders)
- **O**: New meat categories don't modify existing code; extend via new products
- **L**: Repository interfaces allow swapping PostgreSQL with another DB
- **I**: Small, focused interfaces (e.g., `INotificationProvider`, `IPaymentGateway`)
- **D**: High-level modules depend on abstractions, not concrete implementations

## 6. Component Diagram

```
┌────────────────────────────────────────────────────────────────────┐
│                      FRONTEND CLIENTS                               │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌──────────────┐ │
│  │ Flutter    │  │ Flutter    │  │ Next.js    │  │ WhatsApp     │ │
│  │ Android    │  │ Web (PWA)  │  │ Admin      │  │ Bot (Future) │ │
│  └────────────┘  └────────────┘  └────────────┘  └──────────────┘ │
└────────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────────────────┐
│                      API GATEWAY / REVERSE PROXY                    │
│                      Nginx / Traefik                                │
│  - SSL Termination    - Rate Limiting    - Request Logging          │
│  - CORS Management    - IP Whitelisting  - WAF                      │
└────────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────────────────┐
│                    BACKEND SERVICES (FastAPI)                       │
│                                                                     │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌─────────┐  │
│  │ Auth     │ │ Product  │ │ Order    │ │ Payment  │ │ Admin   │  │
│  │ Service  │ │ Service  │ │ Service  │ │ Service  │ │ Service │  │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘ └─────────┘  │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────────────┐  │
│  │ Cart     │ │ Notif    │ │ Subscrip │ │ Analytics            │  │
│  │ Service  │ │ Service  │ │ Service  │ │ Service              │  │
│  └──────────┘ └──────────┘ └──────────┘ └──────────────────────┘  │
│                                                                     │
│  Middleware: Auth, Logging, Error Handling, Rate Limit, CORS        │
└────────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌───────────────┐
│  PostgreSQL  │  │   Redis     │  │   Celery    │  │  Cloudinary   │
│  (Primary)   │  │  (Cache)    │  │  (Workers)  │  │  (Storage)    │
└─────────────┘  └─────────────┘  └─────────────┘  └───────────────┘
```

## 7. Redis Caching Strategy

| Cache Key | TTL | Purpose |
|-----------|-----|---------|
| `products:all` | 5 min | Product catalog listing |
| `products:{id}` | 10 min | Single product detail |
| `categories` | 1 hour | Category list |
| `freshness:today` | 1 min | Today's stock arrivals |
| `promotions:active` | 15 min | Active promo codes |
| `otp:{phone}` | 5 min | OTP code storage |
| `cart:{user_id}` | 24 hours | Cart persistence |

## 8. Celery Task Queue

| Task | Queue | Schedule |
|------|-------|----------|
| Send OTP SMS | `sms` | Immediate |
| Send FCM Notification | `notifications` | Immediate |
| Process Payment | `payments` | Immediate |
| Auto-Cancel Unpaid Orders | `orders` | 30 min delay |
| Generate Subscription Orders | `subscriptions` | Daily at 2 AM |
| Clean Up Expired Carts | `maintenance` | Hourly |
| Send Stock Alerts | `inventory` | When stock < threshold |
| Generate Analytics Reports | `analytics` | Daily at 3 AM |
| Backup Database | `maintenance` | Daily at 4 AM |
