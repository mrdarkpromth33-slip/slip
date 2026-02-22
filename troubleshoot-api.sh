#!/bin/bash

echo "🔧 PromptPay API Troubleshooting & Fix"
echo "======================================="
echo ""

# SSH to VPS and troubleshoot
cat > /tmp/api-troubleshoot.sh << 'ENDSCRIPT'
#!/bin/bash

cd /opt/promptpay-system

echo "[1] Checking API container status..."
docker ps -a | grep slip_api

echo ""
echo "[2] Getting API logs..."
docker logs slip_api

echo ""
echo "[3] Checking if database is ready..."
docker exec slip_postgres pg_isready -U slip_user -d slip_db

echo ""
echo "[4] Checking Docker image..."
docker images | grep promptpay-system

echo ""
echo "[5] Attempting to rebuild and start..."
docker-compose down
docker-compose build --no-cache slip_api

echo ""
echo "[6] Starting only API service..."
docker-compose up -d slip_api

echo ""
sleep 3

echo "[7] Final status check..."
docker ps

echo ""
echo "[8] API logs after restart..."
docker logs --tail=20 slip_api

ENDSCRIPT

chmod +x /tmp/api-troubleshoot.sh

# Transfer and run it via SSH (using scp + sh)
echo "Transferring troubleshooting script to VPS..."
scp -q /tmp/api-troubleshoot.sh root@150.95.84.201:/tmp/

echo "Running troubleshooting script on VPS..."
echo ""

ssh -o ConnectTimeout=5 root@150.95.84.201 'bash /tmp/api-troubleshoot.sh' 2>&1
