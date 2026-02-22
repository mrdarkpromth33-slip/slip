#!/bin/bash

#╔═══════════════════════════════════════════════════════════════╗
#║  PromptPay Payment System - Complete VPS Recovery Script      ║
#║  Usage: ./complete-vps-recovery.sh <vps-ip> <username>       ║
#╚═══════════════════════════════════════════════════════════════╝

VPS_IP="${1:-150.95.84.201}"
VPS_USER="${2:-root}"
VPS_PASSWORD="${3:-Laline1812@}"

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║          PromptPay VPS Recovery - Complete Process           ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "Configuration:"
echo "  • VPS IP: $VPS_IP"
echo "  • User: $VPS_USER"
echo "  • System: /opt/promptpay-system/"
echo ""

# Check if expect is available (needed for password-based SSH)
if ! command -v expect &> /dev/null; then
    echo "⚠️  'expect' not found. Installing..."
    apt-get update -qq && apt-get install -y expect > /dev/null 2>&1 || {
        echo "ℹ️  Cannot install expect. Using interactive SSH instead."
        echo "    You will be prompted for password."
    }
fi

# Prepare the remote script that will run on VPS
cat > /tmp/vps-recovery.sh << 'VPSSCRIPT'
#!/bin/bash

set -e

PROJECT_DIR="/opt/promptpay-system"
ORANGE='\033[0;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${ORANGE}[1/8] System Information${NC}"
echo "  Hostname: $(hostname)"
echo "  Kernel: $(uname -r)"
echo "  Docker: $(docker --version)"
echo ""

echo -e "${ORANGE}[2/8] Killing conflicting services${NC}"
if pgrep -x "postgres" > /dev/null; then
    echo "  Stopping system PostgreSQL..."
    pkill -9 postgres 2>/dev/null || true
    sleep 1
    echo "  ✓ PostgreSQL stopped"
else
    echo "  ✓ No conflicting postgres found"
fi

echo ""
echo -e "${ORANGE}[3/8] Restarting Docker${NC}"
systemctl restart docker
sleep 2
docker ps > /dev/null && echo "  ✓ Docker daemon ready" || echo "  ⚠ Docker may need more time"

echo ""
echo -e "${ORANGE}[4/8] Preparing docker-compose${NC}"
cd "$PROJECT_DIR"
echo "  Working directory: $(pwd)"

# Verify files exist
if [ -f "docker-compose.yml" ] && [ -f "main.py" ]; then
    echo "  ✓ docker-compose.yml found"
    echo "  ✓ main.py found"
else
    echo "  ✗ Critical files missing!"
    exit 1
fi

echo ""
echo -e "${ORANGE}[5/8] Removing old containers${NC}"
docker-compose down -v 2>&1 | grep -E "Removing|removed|stopped" || echo "  ✓ Clean start"

echo ""
echo -e "${ORANGE}[6/8] Starting services${NC}"
docker-compose up -d 2>&1 | grep -E "Created|created|Starting" || echo "  ✓ Services starting"

echo ""
echo -e "${ORANGE}[7/8] Waiting for services to stabilize${NC}"
sleep 5

echo -e "${GREEN}✓ Services startup complete${NC}"

echo ""
echo -e "${ORANGE}[8/8] Final Status${NC}"

# Get container status
CONTAINERS=$(docker ps -a --format "{{.Names}}:{{.Status}}" 2>/dev/null)
API_RUNNING=0
DB_RUNNING=0
PGADMIN_RUNNING=0

echo "$CONTAINERS" | while IFS=: read -r name status; do
    echo "  $name -> $status"
done

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                    SERVICE ENDPOINTS                          ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Get external ports
DOCKER_HOST=$(hostname -I | awk '{print $1}')
echo -e "${GREEN}From WebBrowser:${NC}"
echo "  • API Docs:   http://$DOCKER_HOST:8000/docs"
echo "  • Database:   http://$DOCKER_HOST:5050"
echo ""

echo -e "${GREEN}From VPS Console:${NC}"
echo "  • API Test:   curl http://localhost:8000/docs"
echo "  • DB Test:    curl http://localhost:5432"
echo ""

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                   IMPORTANT COMMANDS                          ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "View logs:"
echo "  docker-compose logs -f slip_api"
echo ""
echo "Test API endpoint:"
echo "  curl -X POST http://localhost:8000/api/payment/generate-qr \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"amount\": 100}'"
echo ""
echo "Stop services:"
echo "  docker-compose down"
echo ""
echo "Full restart:"
echo "  docker-compose restart"
echo ""

VPSSCRIPT

# Copy script to VPS
echo "Transferring recovery script to VPS..."
scp -o StrictHostKeyChecking=no -o ConnectTimeout=3 \
    /tmp/vps-recovery.sh "$VPS_USER@$VPS_IP:/tmp/" 2>/dev/null || {
    echo "ℹ️  Using interactive SSH to upload and execute..."
}

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                EXECUTING RECOVERY PROCESS                     ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Execute the script
ssh -o StrictHostKeyChecking=no "$VPS_USER@$VPS_IP" "
    bash /tmp/vps-recovery.sh
" 2>&1

# Check result
if [ $? -eq 0 ]; then
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║  ✅ RECOVERY COMPLETE - Services should now be running!       ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Next steps:"
    echo "  1. Wait 10 seconds for full initialization"
    echo "  2. Open http://150.95.84.201:8000/docs in browser"
    echo "  3. Look for Swagger UI with 5 API endpoints"
    echo "  4. Test endpoints using the Swagger interface"
    echo ""
    echo "To verify from command line:"
    echo "  ssh root@150.95.84.201 'docker-compose -f /opt/promptpay-system/docker-compose.yml ps'"
else
    echo ""
    echo "⚠️  Recovery completed but there may be issues."
    echo "SSH to VPS and run: docker-compose logs --tail=50"
fi

# Cleanup
rm -f /tmp/vps-recovery.sh

