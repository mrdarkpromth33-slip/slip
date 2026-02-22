#!/bin/bash

# PromptPay Payment System - Automated Service Startup

set -e

VPS_IP="${1:-150.95.84.201}"
VPS_USER="${2:-root}"

echo "╔════════════════════════════════════════════╗"
echo "║  PromptPay System - Automated Startup      ║"
echo "╚════════════════════════════════════════════╝"
echo ""
echo "[*] Target VPS: $VPS_USER@$VPS_IP"
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Create the remote execution script
REMOTE_SCRIPT=$(cat << 'ENDSCRIPT'
#!/bin/bash

echo "[1/6] Killing conflicting PostgreSQL service..."
pkill -9 postgres 2>/dev/null || echo "    No postgres process found"
sleep 1

echo "[2/6] Restarting Docker daemon..."
systemctl restart docker
sleep 2

echo "[3/6] Navigating to system directory..."
cd /opt/promptpay-system

echo "[4/6] Stopping and removing old containers..."
docker-compose down -v 2>&1 | grep -E "(Removing|Stopped|Removed)" || echo "    No old containers to remove"

echo "[5/6] Starting services..."
docker-compose up -d 2>&1 | grep -E "(Creating|Created|Starting|Started)" || echo "    Services initialized"

echo "[6/6] Waiting for services to be healthy..."
sleep 5

# Show status
echo ""
echo "╔════════════════════════════════════════════╗"
echo "║          SERVICE STATUS                    ║"
echo "╚════════════════════════════════════════════╝"
echo ""
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "Testing API connectivity..."
if docker exec slip_api curl -s http://localhost:8000/docs > /dev/null 2>&1; then
    echo -e "✅ API is responding on port 8000"
else
    echo -e "⚠️  API test (may need a moment more to warm up)"
fi

echo ""
echo "╔════════════════════════════════════════════╗"
echo "║          ACCESS INFORMATION                ║"
echo "╚════════════════════════════════════════════╝"
echo ""
echo "🌐 API Documentation:"
echo "   http://150.95.84.201:8000/docs"
echo ""
echo "📊 Database Management (pgAdmin):"
echo "   http://150.95.84.201:5050"
echo "   Email: admin@example.com"
echo "   Password: admin"
echo ""
echo "📝 Test API with curl:"
echo "   curl -X POST http://150.95.84.201:8000/api/payment/generate-qr \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -d '{\"amount\": 100}'"
echo ""

ENDSCRIPT
)

# Execute the script on VPS
echo "[*] Executing startup commands on VPS..."
echo ""

ssh -o StrictHostKeyChecking=no "$VPS_USER@$VPS_IP" << EOF
$REMOTE_SCRIPT
EOF

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Startup successful!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Wait 3-5 seconds for full initialization"
    echo "  2. Open http://150.95.84.201:8000/docs in your browser"
    echo "  3. Use the Swagger interface to test the API"
else
    echo ""
    echo -e "${RED}❌ Startup may have encountered issues${NC}"
    echo "Run this to check logs:"
    echo "  ssh root@150.95.84.201 'docker-compose logs --tail=50'"
fi

