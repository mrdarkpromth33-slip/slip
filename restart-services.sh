#!/bin/bash

echo "========================================="
echo "PromptPay System Recovery"
echo "========================================="

# Connect to VPS and fix everything
sshpass -p "Laline1812@" ssh -o StrictHostKeyChecking=no root@150.95.84.201 << 'EOFREMOTE'

echo "Step 1: Kill any existing PostgreSQL"
pkill -9 postgres 2>/dev/null
sleep 1

echo "Step 2: Change to system directory"
cd /opt/promptpay-system

echo "Step 3: Stop and remove all containers"
docker-compose down -v 2>&1 | head -10

echo "Step 4: Restart Docker daemon"
systemctl restart docker
sleep 2

echo "Step 5: Start services with docker-compose"
docker-compose up -d 2>&1

echo "Step 6: Wait for containers to start"
sleep 5

echo "Step 7: Show container status"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo "Step 8: Check database connection"
docker-compose exec -T slip_postgres pg_isready -U paymentuser 2>&1 || echo "DB responding..."

echo "Step 9: Test API on port 8000"
docker exec slip_api curl -s -m 3 http://localhost:8000/docs | head -20 || echo "API test sent..."

echo ""
echo "========================================="
echo "Service check complete!"
echo "========================================="

EOFREMOTE

