#!/bin/bash

# Final verification - check VPS services via SSH with proper setup

echo "📋 PromptPay Deployment Verification"
echo "===================================="
echo ""

# Create a temporary script on VPS to check status
VPSSCRIPT=$(mktemp)
cat > "$VPSSCRIPT" << 'ENDOFSCRIPT'
#!/bin/bash
cd /opt/promptpay-system || exit 1

# Start services if not running
echo "Starting docker-compose services..."
docker-compose up -d 2>&1 | grep -E "Created|Started|already in use" || echo "Services started"

sleep 5

echo ""
echo "Container Status:"
docker-compose ps

echo ""
echo "Network Status:"
docker network ls

echo ""
echo "Checking if API port is open:"
docker exec slip_api netstat -tlnp 2>/dev/null | grep 8000 || echo "Checking from host..."
ss -tlnp 2>/dev/null | grep 8000 || echo "Port 8000 not found in netstat"

echo ""
echo "API Health Check:"
curl -s -m 5 http://localhost:8000/docs | head -1 || echo "API not responding on localhost"

echo ""
echo "Environment Variables:"
cat .env 2>/dev/null | grep -E "DATABASE|API|HOST" | head -5 || echo "No .env file"

echo ""
echo "Docker Logs (API Container):"
docker-compose logs slip_api --tail=5 2>/dev/null | head -20

echo ""
echo "File Verification:"
ls -lh main.py docker-compose.yml requirements.txt | awk '{print $9, $5}'
ENDOFSCRIPT

# Copy script to VPS and execute
scp -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$VPSSCRIPT" root@150.95.84.201:/tmp/check.sh 2>&1 | grep -v "Warning\|password"
sleep 1

# Execute remotely
echo "(Connecting to VPS...)"
ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no root@150.95.84.201 'bash /tmp/check.sh' 2>&1 | grep -v "^Warning\|permission denied\|password"

rm -f "$VPSSCRIPT"
