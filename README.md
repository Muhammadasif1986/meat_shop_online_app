# Abdul Ghaffar Meat Shop 🥩

**Location:** Naval Colony  
**Type:** Fresh Beef, Chicken & Mutton Delivery Service  
**Platform:** Android + Web

A modern meat delivery platform serving Naval Colony and nearby societies with fresh halal meat delivered within 20-30 minutes.

---

## System Overview

```
┌─────────────────────────────────────────────────────┐
│                   ABDUL GHAFFAR                      │
│                    MEAT SHOP                          │
├───────────────────┬─────────────────────────────────┤
│                   │                                  │
│   Mobile App      │   Admin Dashboard                │
│   (Flutter)       │   (Next.js)                      │
│                   │                                  │
├───────────────────┴─────────────────────────────────┤
│                   REST API                            │
│               (FastAPI - Python)                      │
├───────────────────┬─────────────────────────────────┤
│   PostgreSQL      │   Redis / Celery                 │
│   (Primary DB)    │   (Background Tasks)             │
├───────────────────┼─────────────────────────────────┤
│   Firebase        │   Cloudinary                     │
│   (Notifications) │   (Media Storage)                │
└───────────────────┴─────────────────────────────────┘
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile App | Flutter (Android + Responsive Web) |
| Admin Dashboard | Next.js 14 (React, TypeScript) |
| Backend API | FastAPI (Python 3.11+) |
| Database | PostgreSQL 15 |
| Cache/Queue | Redis + Celery |
| Auth | JWT + Phone OTP |
| Notifications | Firebase Cloud Messaging |
| Storage | Cloudinary / AWS S3 |
| Deployment | Docker, Railway / AWS, Vercel |

## Project Structure

```
├── docs/          # PRD, architecture, API specs, UI specs
├── backend/       # FastAPI application
├── mobile/        # Flutter mobile app
├── admin/         # Next.js admin dashboard
├── docker/        # Docker compose & deployment configs
├── infra/         # Terraform & K8s manifests
└── scripts/       # Utility scripts
```

## Quick Start

```bash
# Backend
cd backend && docker-compose up -d

# Admin Dashboard
cd admin && npm install && npm run dev

# Mobile App
cd mobile && flutter pub get && flutter run
```

## Documentation Index

| Doc | Description |
|-----|-------------|
| `docs/01-prd.md` | Product Requirements Document |
| `docs/02-database-schema.sql` | Full SQL schema with indexes |
| `docs/03-api-spec.md` | Complete API specification |
| `docs/04-system-architecture.md` | Architecture & design decisions |
| `docs/05-ui-specifications.md` | Screen-by-screen UI specs & flows |
| `docs/06-security-scalability.md` | Security, scaling, CI/CD, testing |

---
*Built for Naval Colony — Fresh meat, delivered fast.*
