#!/bin/bash

# Start the PromptPay system using docker-compose

echo "🚀 Starting PromptPay Payment System..."
echo "========================================"

ssh -o StrictHostKeyChecking=no root@150.95.84.201 << 'REMOTE_EOF'

cd /opt/promptpay-system

echo "📦 Building Docker images..."
docker-compose build --no-cache 2>&1 | grep -E "Building|Successfully|ERROR" || true

echo ""
echo "🎯 Starting services..."
docker-compose up -d

echo ""
echo "⏳ Waiting for services to initialize..."
sleep 5

echo ""
echo "📊 Service Status:"
docker-compose ps

echo ""
echo "📋 Checking API health..."
curl -s http://localhost:8000/docs | grep -q "Swagger UI" && echo "✅ API is running" || echo "⚠️  API initializing..."

echo ""
echo "🗄️  Database status:"
docker exec promptpay-db pg_isready -U promptpay || echo "Database connecting..."

echo ""
echo "📋 Container logs (last 10 lines):"
docker-compose logs --tail=10

REMOTE_EOF

echo ""
echo "========================================"
echo "🌍 System URLs:"
echo "  API Docs:  http://150.95.84.201:8000/docs"
echo "  Database:  http://150.95.84.201:5050"
echo "            (pgAdmin: admin@example.com / password)"
echo ""
echo "📝 Test endpoint:"
echo "  curl http://150.95.84.201:8000/api/payment/generate-qr -d '{\"amount\": 100}' -H 'Content-Type: application/json'"
