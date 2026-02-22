#!/bin/bash

echo "🚀 Starting PromptPay containers..."

ssh -o StrictHostKeyChecking=no -T root@150.95.84.201 << 'REMOTE_EOF'
cd /opt/promptpay-system

echo "Stopping any existing containers..."
docker-compose down 2>/dev/null || true

echo "Pulling/building images..."
docker-compose build --no-cache

echo "Starting services in background..."
docker-compose up -d

echo "Waiting for services to initialize..."
sleep 10

echo ""
echo "=== Container Status ==="
docker-compose ps

echo ""
echo "=== Waiting for API to be ready ==="
for i in {1..30}; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/docs 2>/dev/null || echo "000")
    if [ "$STATUS" = "200" ]; then
        echo "✅ API is ready!"
        break
    fi
    echo "⏳ Attempt $i/30 - API status: $STATUS"
    sleep 2
done

echo ""
echo "=== Final Status ==="
docker-compose ps

echo ""
echo "✅ System is live on http://150.95.84.201:8000/docs"

REMOTE_EOF

echo ""
echo "Done!"
