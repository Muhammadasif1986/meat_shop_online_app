#!/bin/bash
set -e

echo "=== AGMS Production Deploy ==="

# 1. Build and push Docker images
echo "Building backend image..."
docker build -t agms-backend:latest backend/

echo "Building admin image..."
docker build -t agms-admin:latest \
  --build-arg NEXT_PUBLIC_API_URL=https://api.agms.com/api/v1 \
  admin/

# 2. Push to registry (replace with your registry)
# docker tag agms-backend:latest registry.example.com/agms-backend:latest
# docker tag agms-admin:latest registry.example.com/agms-admin:latest
# docker push registry.example.com/agms-backend:latest
# docker push registry.example.com/agms-admin:latest

# 3. Deploy via docker-compose
echo "Starting services with docker-compose..."
docker compose -f docker-compose.prod.yml up -d

echo "=== Deploy complete ==="
echo "Backend: http://localhost:8000"
echo "Admin:   http://localhost:3000"
