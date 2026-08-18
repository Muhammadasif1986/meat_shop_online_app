# Security, Scalability, CI/CD & Testing — Abdul Ghaffar Meat Shop

---

## 1. SECURITY DESIGN

### 1.1 Authentication & Authorization

```
┌─────────────────────┐      ┌─────────────────────┐
│     Client          │      │     FastAPI          │
│                     │      │                      │
│  1. Send phone      │─────►│  2. Generate OTP,    │
│                     │      │     store in Redis   │
│  3. Enter OTP       │─────►│  4. Verify OTP,      │
│                     │      │     issue JWT        │
│  5. Store JWT       │◄─────│  5. Return tokens    │
│     securely        │      │                      │
└─────────────────────┘      └──────────────────────┘
```

- **JWT Structure**: Access (1hr) + Refresh (7 days)
- **Token Storage (Mobile)**: FlutterSecureStorage (encrypted)
- **Token Storage (Web)**: httpOnly cookie (admin), localStorage (web app)
- **Password Policy**: For admin: min 8 chars, 1 uppercase, 1 number, 1 special
- **OTP Rate Limit**: Max 3 attempts per OTP, 5 OTPs per hour per phone

### 1.2 API Security

- **HTTPS Only**: TLS 1.3 enforced at load balancer
- **Rate Limiting**: 100 req/min per IP, 20 req/min on auth endpoints
- **CORS**: Whitelist specific origins only
- **Request Validation**: Pydantic schemas for all inputs
- **SQL Injection Prevention**: SQLAlchemy ORM (parameterized queries)
- **No Secrets in Code**: All secrets via environment variables / Vault

### 1.3 Data Security

- **At Rest**: PostgreSQL encryption at rest (AES-256)
- **In Transit**: TLS for all external and internal communications
- **Passwords**: bcrypt (12 rounds) for admin accounts
- **PII**: Phone numbers encrypted in logs, masked in exports
- **Database Access**: Separate read-only user for analytics

### 1.4 Infrastructure Security

- **Docker Images**: Minimal base images, regular vulnerability scanning
- **Container Isolation**: Non-root user in containers
- **Network Policies**: Micro-segmentation, only necessary ports exposed
- **WAF**: Web Application Firewall on the edge
- **DDoS Protection**: CloudFlare or AWS Shield

### 1.5 Admin Security

- **2FA**: Optional but recommended for admin accounts
- **IP Whitelisting**: Admin panel accessible only from trusted IPs
- **Session Management**: Admin sessions expire after 30 min inactivity
- **Audit Logging**: All admin actions logged with timestamp, IP, user agent

---

## 2. SCALABILITY PLAN

### 2.1 Vertical Scaling (Phase 1 — Up to 1K DAU)

- Single PostgreSQL instance (db.r6g.large — 2 vCPU, 16GB RAM)
- Single FastAPI server (4 workers, 2 vCPU)
- Redis on same instance
- Cost-effective, simple to manage

### 2.2 Horizontal Scaling (Phase 2 — 1K to 10K DAU)

```
                      ┌──────────────┐
                      │  Load Balancer│
                      └──────┬───────┘
                             │
          ┌──────────────────┼──────────────────┐
          ▼                  ▼                  ▼
   ┌────────────┐    ┌────────────┐    ┌────────────┐
   │  API       │    │  API       │    │  API       │
   │  Instance 1│    │  Instance 2│    │  Instance N│
   └────────────┘    └────────────┘    └────────────┘
          │                  │                  │
          └──────────────────┼──────────────────┘
                             │
                    ┌────────┴────────┐
                    │  PostgreSQL     │
                    │  (Primary +     │
                    │   Read Replica) │
                    └─────────────────┘
```

- **API**: FastAPI behind Nginx load balancer, horizontal auto-scaling
- **Database**: PostgreSQL read replicas for reporting, connection pooling (PgBouncer)
- **Redis**: ElastiCache cluster for cache + rate limiting
- **Celery**: Separate worker auto-scaling group
- **Media**: Cloudinary CDN for image delivery

### 2.3 Caching Strategy (Detailed)

| Level | Cache | Hit Rate Target | Invalidation Strategy |
|-------|-------|----------------|----------------------|
| Browser | ETag headers | 60% | Response-based |
| CDN | Cloudinary for images | 90% | URL-based versioning |
| Application | Redis | 80% | TTL + event-based |
| Database | PostgreSQL query cache | 70% | Internal |

### 2.4 Database Optimizations

- **Connection Pooling**: PgBouncer (transaction mode, 100 pool size)
- **Indexes**: All query patterns covered (created in schema)
- **Partitioning**: Orders table partitioned by month (future)
- **Materialized Views**: Daily analytics pre-computed
- **Read Replicas**: Analytics and reporting queries directed to replica

### 2.5 Performance Targets

| Metric | Target | Measurement |
|--------|--------|-------------|
| API P50 Response | < 100ms | DataDog APM |
| API P95 Response | < 200ms | DataDog APM |
| App Cold Start | < 3s | Firebase Performance |
| App Page Load | < 2s | Firebase Performance |
| Database Queries | < 50ms | pg_stat_statements |
| Concurrent Users | 1,000 | Load testing |
| Peak Orders/Hour | 200 | Load testing |

---

## 3. CI/CD STRATEGY

### 3.1 Pipeline Overview

```
┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
│  Commit  │──►│   Lint   │──►│   Test   │──►│  Build   │──►│  Deploy  │
│  (PR)    │   │  & Type  │   │  (Unit + │   │  (Docker │   │  (Staging│
│          │   │  Check   │   │  Integ.) │   │  Image)  │   │  / Prod) │
└──────────┘   └──────────┘   └──────────┘   └──────────┘   └──────────┘
```

### 3.2 GitHub Actions Workflow

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  backend:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15
        env: { POSTGRES_DB: test, POSTGRES_PASSWORD: test }
      redis:
        image: redis:7

    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: "3.11" }
      - run: pip install -r requirements.txt
      - run: ruff check app/
      - run: mypy app/
      - run: pytest tests/ --cov=app --cov-report=xml
      - run: docker build -t backend .

  mobile:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { flutter-version: "3.22" }
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test --coverage
      - run: flutter build apk --release

  admin:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: "20" }
      - run: npm ci
      - run: npm run lint
      - run: npm run typecheck
      - run: npm test
      - run: npm run build

  deploy:
    needs: [backend, mobile, admin]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - run: echo "Deploying to production..."
      # Deploy backend to Railway/AWS
      # Deploy admin to Vercel
      # Upload APK to Firebase App Distribution
```

### 3.3 Environment Strategy

| Environment | Purpose | URL | DB | Deploy Trigger |
|-------------|---------|-----|----|---------------|
| `development` | Local dev | localhost:8000 | Local | Manual |
| `staging` | Integration testing | staging.api.agms.com | Staging RDS | Push to develop |
| `production` | Live | api.abdulghaffarmeatshop.com | Prod RDS | Push to main |

### 3.4 Deployment Architecture

```
                    ┌──────────────────────┐
                    │   CloudFlare DNS     │
                    └──────────┬───────────┘
                               │
                    ┌──────────▼───────────┐
                    │   AWS ALB / Nginx    │
                    └──────────┬───────────┘
                               │
          ┌────────────────────┼────────────────────┐
          ▼                    ▼                    ▼
   ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
   │  Backend     │    │  Admin       │    │  Media       │
   │  (Railway/   │    │  (Vercel)    │    │  (Cloudinary)│
   │   AWS ECS)   │    │              │    │              │
   └──────────────┘    └──────────────┘    └──────────────┘
          │
          ▼
   ┌──────────────┐    ┌──────────────┐
   │  PostgreSQL  │    │  Redis       │
   │  (AWS RDS)   │    │  (ElastiCache│
   └──────────────┘    └──────────────┘
```

---

## 4. TESTING STRATEGY

### 4.1 Testing Pyramid

```
        ╱╲
       ╱  ╲           E2E Tests (Cypress / Detox)
      ╱    ╲          Coverage: 10% — Critical user journeys
     ╱      ╲
    ╱────────╲
   ╱          ╲       Integration Tests (pytest / playwright)
  ╱            ╲      Coverage: 30% — API contracts, DB interaction
 ╱              ╲
╱────────────────╲
╱                  ╲   Unit Tests (pytest / flutter_test / jest)
╱                    ╲  Coverage: 60% — Business logic, services
╱──────────────────────╲
```

### 4.2 Backend Testing

| Test Type | Tool | Scope | Target Coverage |
|-----------|------|-------|----------------|
| Unit | pytest + pytest-asyncio | Services, utils, schemas | 80% |
| Integration | pytest + TestClient | API endpoints, DB access | 70% |
| API Contract | pytest + schemathesis | OpenAPI spec compliance | 100% routes |
| Load | locust / k6 | Simulate 1000 concurrent users | Critical flows |

### 4.3 Mobile Testing

| Test Type | Tool | Scope |
|-----------|------|-------|
| Unit | flutter_test | ViewModels, models, utils |
| Widget | flutter_test | Widget rendering, interaction |
| Integration | integration_test | User flows across screens |
| E2E | Detox (future) | Full app on real device |

### 4.4 Admin Testing

| Test Type | Tool | Scope |
|-----------|------|-------|
| Unit | jest + testing-library | Components, hooks, utils |
| Integration | React Testing Library | Page rendering with API mock |
| E2E | Cypress | Admin flows (CRUD, status changes) |

### 4.5 Test Data Strategy

- **Fixtures**: Pre-defined seed data for `pytest` conftest.py
- **Factories**: `factory_boy` for generating test entities
- **Mocks**: `unittest.mock` for external services (SMS, FCM, payments)
- **Database**: Test PostgreSQL in Docker, migrations applied per test run

### 4.6 Quality Gates

| Gate | Criteria | Blocking? |
|------|----------|-----------|
| Lint | 0 errors, 0 warnings | Yes |
| Types | mypy strict mode, 0 errors | Yes |
| Unit Tests | 80%+ coverage | Yes |
| Integration Tests | All critical paths pass | Yes |
| Security Scan | 0 critical/high vulns | Yes |
| Build | Docker image builds | Yes |
| Bundle Size | APK < 30MB | No (warning) |

---

## 5. MONITORING & OBSERVABILITY

| Tool | Purpose |
|------|---------|
| Sentry | Error tracking (backend + mobile) |
| DataDog / Grafana | APM, metrics, dashboards |
| Prometheus | System metrics collection |
| Loki | Log aggregation |
| UptimeRobot | Uptime monitoring |
| Firebase Crashlytics | Mobile crash reporting |

### Key Alerts

- API 5xx rate > 1% in 5 minutes
- API P95 latency > 500ms
- Database connections > 80% pool
- Disk space < 20% free
- Failed orders > 5% in 1 hour
- Stock < threshold for any product
