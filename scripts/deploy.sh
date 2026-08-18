#!/bin/bash
# Production deployment script
set -e

ENVIRONMENT=${1:-production}
echo "=== Deploying to $ENVIRONMENT ==="

# Build and push Docker images
echo ">>> Building API image..."
docker build -t ghcr.io/your-org/agms-api:latest backend/
docker push ghcr.io/your-org/agms-api:latest

# Deploy backend
echo ">>> Deploying backend..."
docker compose -f docker/docker-compose.prod.yml up -d

# Run migrations
echo ">>> Running migrations..."
docker compose -f docker/docker-compose.prod.yml exec api alembic upgrade head

# Deploy admin dashboard to Vercel
echo ">>> Deploying admin dashboard..."
cd admin
npx vercel --prod
cd ..

echo ">>> Deploy complete!"
