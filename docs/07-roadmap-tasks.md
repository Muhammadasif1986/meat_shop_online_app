# Roadmap & Development Tasks — Abdul Ghaffar Meat Shop

---

## 1. MVP ROADMAP (Weeks 1–6)

### Phase 1: Foundation (Week 1)

| Day | Task | Owner | Deliverable |
|-----|------|-------|-------------|
| 1-2 | Project scaffolding: backend, mobile, admin repos | BE Lead | Repos with CI/CD |
| 1-2 | Docker compose setup (Postgres, Redis, API) | BE Lead | Local dev env |
| 3-4 | Database schema implementation (Alembic migrations) | BE Lead | All tables created |
| 3-4 | Base FastAPI setup (config, DB, security, middleware) | BE Lead | Working API skeleton |
| 5 | Admin Next.js setup + Tailwind + layout | FE Lead | Admin shell |
| 5 | Flutter project setup + theme + routing | Mobile Lead | App shell |

### Phase 2: Auth & Products (Week 2)

| Day | Task | Owner | Deliverable |
|-----|------|-------|-------------|
| 6-7 | OTP generation + verification API | BE Lead | /auth/send-otp, /verify-otp |
| 6-7 | JWT token management + refresh | BE Lead | Secure auth flow |
| 8 | Phone input + OTP screens (Flutter) | Mobile Lead | Login flow complete |
| 8 | Admin login page (Next.js) | FE Lead | Admin auth |
| 9-10 | Products CRUD API + categories | BE Lead | /products, /categories |
| 9-10 | Product list + detail screens (Flutter) | Mobile Lead | Product browsing |
| 10 | Admin product CRUD pages | FE Lead | Product management |

### Phase 3: Cart & Orders (Weeks 3–4)

| Day | Task | Owner | Deliverable |
|-----|------|-------|-------------|
| 11-12 | Cart API (add, update, remove, clear) | BE Lead | /cart endpoints |
| 11-12 | Cart screen with edit/remove (Flutter) | Mobile Lead | Working cart |
| 13-14 | Order creation from cart API | BE Lead | /orders POST |
| 13-14 | Checkout screen + address input (Flutter) | Mobile Lead | Order placement |
| 15-16 | Order management API (list, detail, status) | BE Lead | /orders endpoints |
| 15-16 | Order tracking screen (Flutter) | Mobile Lead | Status timeline |
| 16 | Admin order management page | FE Lead | Status updates |

### Phase 4: Delivery & Admin Core (Weeks 5–6)

| Day | Task | Owner | Deliverable |
|-----|------|-------|-------------|
| 17-18 | Address management API + screens | BE + Mobile | Saved addresses |
| 17-18 | Delivery scheduling (ASAP + slots) | BE Lead | Time slot logic |
| 19-20 | Admin dashboard stats API | BE Lead | /admin/dashboard/stats |
| 19-20 | Admin dashboard page with charts | FE Lead | Stats cards + chart |
| 21-22 | Rider assignment flow (admin) | BE + FE | Assign rider UI |
| 21-22 | Rider API (orders, status updates) | BE Lead | /rider endpoints |
| 23-24 | Polish, bug fixes, edge cases | All | Stable MVP |
| 23-24 | **MVP Launch** | All | **v1.0 Live** |

### MVP Deliverables Summary

- [x] Phone auth with OTP
- [x] Product catalog (Beef, Chicken, Mutton)
- [x] Cart with weight/cut selection
- [x] Checkout with delivery scheduling
- [x] Order tracking (6 statuses)
- [x] Admin order management
- [x] Basic rider flow
- [x] Admin dashboard with stats
- [x] Docker development environment

---

## 2. PRODUCTION ROADMAP (Weeks 7–14)

### Phase 5: Enhanced Features (Weeks 7–8)

| Week | Feature | Details |
|------|---------|---------|
| 7 | Reviews & Ratings | API + Flutter screen + admin moderation |
| 7 | Push Notifications | FCM integration, order status alerts |
| 8 | Reorder Feature | One-click reorder from history |
| 8 | Promotions Engine | Discount codes, admin CRUD, validation |

### Phase 6: Subscriptions & Retention (Weeks 9–10)

| Week | Feature | Details |
|------|---------|---------|
| 9 | Subscription Plans | Weekly/monthly packages |
| 9 | Auto-generate recurring orders | Celery task for subscription orders |
| 10 | Fresh Stock Timer | Arrival time display, countdown |
| 10 | Loyalty Points | Points per order, tier system |

### Phase 7: Scale & Advanced (Weeks 11–14)

| Week | Feature | Details |
|------|---------|---------|
| 11 | Live Rider Tracking | Google Maps integration |
| 11 | Real-time order updates | WebSocket connection |
| 12 | Urdu Language Support | Full localization |
| 12 | WhatsApp Ordering Bot | Twilio WhatsApp API |
| 13 | AI Demand Prediction | ML model for stock prediction |
| 13 | Referral Program | Share codes, rewards |
| 14 | Performance Optimization | Caching, CDN, DB tuning |
| 14 | **v2.0 Production Launch** | **Full feature set** |

---

## 3. DEVELOPMENT TASKS BREAKDOWN

### 3.1 Backend Tasks (FastAPI)

```
Backend Tasks (estimated: 180 hours)
├── Core Infrastructure (30 hrs)
│   ├── Project setup, config, dependencies         2 hrs
│   ├── Database schema + Alembic migrations         6 hrs
│   ├── JWT auth + OTP flow                          6 hrs
│   ├── Redis integration + caching                  4 hrs
│   ├── Celery setup + task queue                    4 hrs
│   ├── Error handling + middleware                  4 hrs
│   └── Rate limiting + security headers             4 hrs
│
├── API Endpoints (80 hrs)
│   ├── Auth (register, login, refresh, logout)      6 hrs
│   ├── Products (CRUD, categories, search)         10 hrs
│   ├── Cart (add, update, remove, promo)           10 hrs
│   ├── Orders (create, list, track, cancel)        12 hrs
│   ├── Addresses (CRUD, geolocation)                6 hrs
│   ├── Reviews (create, list, approve)              6 hrs
│   ├── Subscriptions (CRUD, generate)              10 hrs
│   ├── Promotions (CRUD, validate)                  6 hrs
│   ├── Notifications (list, mark read)              4 hrs
│   ├── Freshness timer endpoint                     2 hrs
│   ├── Rider endpoints (orders, status)             4 hrs
│   └── Admin endpoints (dashboard, analytics)       4 hrs
│
├── Business Logic (40 hrs)
│   ├── Order placement workflow                     8 hrs
│   ├── Stock management + deduction                 4 hrs
│   ├── Delivery fee calculation                     2 hrs
│   ├── Promo code validation                        4 hrs
│   ├── Subscription order generation                8 hrs
│   ├── Notification dispatch (FCM)                  6 hrs
│   ├── SMS integration (Twilio)                     4 hrs
│   └── Invoice generation                           4 hrs
│
├── Celery Tasks (10 hrs)
│   ├── Generate subscription orders                 3 hrs
│   ├── Clean expired carts                          1 hr
│   ├── Send stock alerts                            2 hrs
│   ├── Auto-cancel pending orders                   2 hrs
│   └── Analytics report generation                  2 hrs
│
├── Testing (20 hrs)
│   ├── Unit tests for services                     10 hrs
│   ├── Integration tests for APIs                   6 hrs
│   └── Load testing (Locust/k6)                     4 hrs
│
└── DevOps (20 hrs)
    ├── Docker compose (dev + prod)                  4 hrs
    ├── CI/CD pipeline (GitHub Actions)               6 hrs
    ├── Terraform (AWS infra)                        6 hrs
    └── Monitoring (Sentry, DataDog)                  4 hrs
```

### 3.2 Flutter Mobile Tasks

```
Flutter Tasks (estimated: 150 hours)
├── Core Infrastructure (25 hrs)
│   ├── Project setup + dependencies                 3 hrs
│   ├── Theme + design system                        4 hrs
│   ├── Dio client + interceptors                    4 hrs
│   ├── Secure storage + token management             3 hrs
│   ├── State management (Bloc/Cubit)                5 hrs
│   ├── Firebase setup (FCM, Auth)                   4 hrs
│   └── Routing + navigation                         2 hrs
│
├── Auth Screens (15 hrs)
│   ├── Splash screen                                2 hrs
│   ├── Welcome screen                               3 hrs
│   ├── Phone input screen                           4 hrs
│   └── OTP verification screen                      6 hrs
│
├── Home & Products (25 hrs)
│   ├── Home screen with categories                  6 hrs
│   ├── Fresh stock timer banner                      3 hrs
│   ├── Product grid + search/filter                 6 hrs
│   ├── Product detail screen                        6 hrs
│   └── Category page                                4 hrs
│
├── Cart & Checkout (25 hrs)
│   ├── Cart screen with edit/remove                 6 hrs
│   ├── Weight + cut type selector                   4 hrs
│   ├── Promo code input                             2 hrs
│   ├── Address selection + add screen               5 hrs
│   ├── Delivery time slot picker                    4 hrs
│   └── Order confirmation screen                    4 hrs
│
├── Orders (20 hrs)
│   ├── Orders list screen                           4 hrs
│   ├── Order detail screen                          3 hrs
│   ├── Order tracking timeline                      6 hrs
│   ├── Cancel order flow                            2 hrs
│   └── Reorder functionality                        5 hrs
│
├── Profile & Settings (15 hrs)
│   ├── Profile screen                               4 hrs
│   ├── Address management screen                    4 hrs
│   ├── Notifications screen                         3 hrs
│   └── Language settings                            4 hrs
│
├── Subscriptions (15 hrs)
│   ├── Subscription plans screen                    4 hrs
│   ├── Create subscription flow                     5 hrs
│   ├── Manage subscription screen                   4 hrs
│   └── Subscription history                         2 hrs
│
├── Reviews (10 hrs)
│   ├── Review submission screen                     5 hrs
│   ├── Star rating widget                           2 hrs
│   └── Photo upload                                 3 hrs
│
└── Testing (10 hrs)
    ├── Unit tests                                   4 hrs
    ├── Widget tests                                 4 hrs
    └── Integration tests                            2 hrs
```

### 3.3 Admin Dashboard Tasks (Next.js)

```
Admin Dashboard Tasks (estimated: 100 hours)
├── Core Infrastructure (15 hrs)
│   ├── Next.js project setup + Tailwind              2 hrs
│   ├── Layout (sidebar, header, wrapper)             4 hrs
│   ├── Auth (login page, token management)            3 hrs
│   ├── API client + React Query setup                3 hrs
│   └── Type definitions + shared utils               3 hrs
│
├── Dashboard (15 hrs)
│   ├── Stats cards (orders, revenue, customers)       3 hrs
│   ├── Sales chart (Recharts)                        4 hrs
│   ├── Recent orders table                           3 hrs
│   ├── Low stock alerts widget                       2 hrs
│   └── Top products chart                            3 hrs
│
├── Orders (15 hrs)
│   ├── Orders list with filters                      5 hrs
│   ├── Order detail page                             4 hrs
│   ├── Status change dropdown                        2 hrs
│   ├── Rider assignment dialog                       2 hrs
│   └── Invoice view                                  2 hrs
│
├── Products (15 hrs)
│   ├── Products list table                           3 hrs
│   ├── Add product form (modal)                      4 hrs
│   ├── Edit product form                             3 hrs
│   ├── Stock management (inline edit)                3 hrs
│   └── Categories management                         2 hrs
│
├── Customers (8 hrs)
│   ├── Customer list table                           3 hrs
│   ├── Customer detail page                          3 hrs
│   └── Order history per customer                    2 hrs
│
├── Promotions (8 hrs)
│   ├── Promotions list                               2 hrs
│   ├── Create promo form                             4 hrs
│   └── Usage tracking                                2 hrs
│
├── Reviews (6 hrs)
│   ├── Reviews list                                  2 hrs
│   ├── Approve/reject actions                        2 hrs
│   └── Review detail                                 2 hrs
│
├── Analytics (10 hrs)
│   ├── Revenue chart (daily/monthly)                 3 hrs
│   ├── Orders by category pie chart                  2 hrs
│   ├── Top products bar chart                        2 hrs
│   ├── Date range picker                             2 hrs
│   └── Export CSV                                    1 hr
│
├── Riders (4 hrs)
│   ├── Riders list                                   2 hrs
│   └── Rider performance                             2 hrs
│
└── Testing (4 hrs)
    ├── Component tests                               2 hrs
    └── E2E tests (Cypress)                           2 hrs
```

---

## 4. TEAM STRUCTURE

| Role | Headcount | Responsibilities |
|------|-----------|-----------------|
| Backend Lead (FastAPI) | 1 | API development, DB, infrastructure |
| Flutter Lead | 1 | Mobile app, state management |
| Frontend Lead (Next.js) | 1 | Admin dashboard |
| QA Engineer | 1 | Testing across all platforms |
| Product Manager | 1 | Requirements, prioritization, stakeholder mgmt |
| UI/UX Designer | 0.5 | Design specs, user flows, prototype |

## 5. ESTIMATED TIMELINE

| Phase | Duration | Total Hours |
|-------|----------|-------------|
| MVP (Phase 1-4) | 6 weeks | 720 hrs (4 devs × 30 hrs/wk) |
| Phase 5-6 | 4 weeks | 480 hrs |
| Phase 7 | 4 weeks | 480 hrs |
| **Total** | **14 weeks** | **1,680 hrs** |

## 6. RISK MANAGEMENT

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| OTP delivery delays | Medium | High | Fallback to voice OTP, multiple SMS providers |
| Stock accuracy issues | Medium | High | Admin stock audit tool, physical count reminders |
| Rider availability | High | Medium | Rider pool expansion, backup riders on call |
| Payment failures | Low | Medium | Default to COD, gradual payment gateway rollout |
| Scaling under load | Low | High | Auto-scaling, caching, load testing before launch |
| WhatsApp API restrictions | Medium | Low | Maintain backup SMS/email communication |
