#!/bin/bash
# Development environment setup script
set -e

echo "=== Abdul Ghaffar Meat Shop — Dev Setup ==="

# Check prerequisites
command -v python3 >/dev/null 2>&1 || { echo "Python 3 required"; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "Docker required"; exit 1; }
command -v flutter >/dev/null 2>&1 || echo "Warning: Flutter not found. Install Flutter SDK."
command -v node >/dev/null 2>&1 || echo "Warning: Node.js not found."

# Backend setup
echo ">>> Setting up backend..."
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
echo "Backend ready. Edit .env with your config."

# Docker services
echo ">>> Starting Docker services..."
docker compose up -d postgres redis

# Run migrations
echo ">>> Running database migrations..."
alembic upgrade head

# Seed data
echo ">>> Seeding data..."
python -m app.scripts.seed

echo "=== Setup complete ==="
echo "Start backend: cd backend && source venv/bin/activate && uvicorn app.main:app --reload"
echo "Start admin:   cd admin && npm run dev"
echo "Start mobile:  cd mobile && flutter run"
