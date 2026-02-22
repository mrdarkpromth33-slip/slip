#!/bin/bash

set -e

cd /opt/promptpay-system

echo "═══════════════════════════════════════"
echo "PromptPay API - Full Recovery Script"
echo "═══════════════════════════════════════"
echo ""

echo "[1] Stopping all services..."
docker-compose down -v 2>&1 | head -5

echo "[2] Removing old images..."
docker rmi -f promptpay-system-api 2>/dev/null || true

echo "[3] Building fresh image..."
docker-compose build --no-cache api 2>&1 | grep -E "Step|Successfully|ERROR" | tail -10

echo "[4] Starting containers..."
docker-compose up -d 2>&1 | grep -E "Created|Starting|Started" | head -20

echo "[5] Waiting for services..."
sleep 5

echo ""
echo "═══════════════════════════════════════"
echo "Service Status:"
echo "═══════════════════════════════════════"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "═══════════════════════════════════════"
echo "API Logs:"
echo "═══════════════════════════════════════"
docker logs slip_api 2>&1 | tail -20

echo ""
echo "==="
if docker ps | grep -q "slip_api.*Up"; then
    echo "✅ API is running!"
    echo ""
    echo "Access: http://150.95.84.201:8000/docs"
else
    echo "❌ API is not running. Check logs above."
fi

