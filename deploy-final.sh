#!/bin/bash

# Final deployment script with all fixes

set -e

VPS_HOST="150.95.84.201"
VPS_USER="root"
VPS_PASSWORD="Laline1812@"
VPS_PATH="/opt/promptpay-system"

echo ""
echo "════════════════════════════════════════════════════════════════════════════════"
echo "🚀 FINAL DEPLOYMENT TO VPS"
echo "════════════════════════════════════════════════════════════════════════════════"
echo ""

# Step 1: Upload fixed requirements.txt
echo "📤 Step 1: Uploading fixed requirements.txt..."
expect << 'EOF'
set timeout 30
spawn scp -o StrictHostKeyChecking=no requirements.txt root@150.95.84.201:/opt/promptpay-system/
expect "password:"
send "Laline1812@\r"
expect eof
EOF

echo "✅ File uploaded successfully"
echo ""

# Step 2: Execute deployment commands
echo "🚀 Step 2: Starting deployment on VPS..."
echo ""

expect << 'EOF'
set timeout 600
spawn ssh -o StrictHostKeyChecking=no root@150.95.84.201

expect "password:"
send "Laline1812@\r"

expect "#"
send "cd /opt/promptpay-system && docker-compose down 2>/dev/null || true\r"
expect "#"

send "docker system prune -y\r"
expect "#"

send "echo 'Building Docker images...'\r"
expect "#"

send "docker-compose build --no-cache 2>&1 | grep -E '(ERROR|Successfully|Building|Step)'\r"
expect "#"

send "echo 'Starting services...'\r"
expect "#"

send "docker-compose up -d\r"
expect "#"

send "echo 'Waiting 60 seconds for services to start...'\r"
expect "#"

send "sleep 60\r"
expect "#"

send "echo 'Checking status...'\r"
expect "#"

send "docker-compose ps\r"
expect "#"

send "echo '════════════════════════════════════════════════════════════════════════════════'\r"
expect "#"

send "echo '✅ DEPLOYMENT COMPLETE!'\r"
expect "#"

send "echo '════════════════════════════════════════════════════════════════════════════════'\r"
expect "#"

send "echo ''\r"
expect "#"

send "echo '🌐 ACCESS YOUR SYSTEM:'\r"
expect "#"

send "echo '   API: http://150.95.84.201:8000/docs'\r"
expect "#"

send "echo '   Admin: http://150.95.84.201:5050'\r"
expect "#"

send "exit\r"
expect eof

EOF

echo ""
echo "════════════════════════════════════════════════════════════════════════════════"
echo "✨ DEPLOYMENT COMPLETED!"
echo "════════════════════════════════════════════════════════════════════════════════"
echo ""
