#!/bin/bash

# Fix Docker and Deploy PromptPay System
# This script cleans up Docker conflicts and deploys the system

echo ""
echo "════════════════════════════════════════════════════════════════════════════════"
echo "🔧 FIXING DOCKER & DEPLOYING PROMPTPAY SYSTEM"
echo "════════════════════════════════════════════════════════════════════════════════"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "❌ This script must be run as root"
   exit 1
fi

cd /opt/promptpay-system

echo "📦 Step 1: Removing conflicting Docker packages..."
apt-get remove -y containerd docker.io docker-doc docker-compose docker-ce 2>/dev/null
apt-get autoremove -y 2>/dev/null

echo ""
echo "📦 Step 2: Installing Docker & Docker Compose..."
apt-get update
apt-get install -y docker.io docker-compose

echo ""
echo "📦 Step 3: Starting Docker..."
systemctl start docker
systemctl enable docker

echo ""
echo "📦 Step 4: Verifying Docker installation..."
docker --version
docker-compose --version

echo ""
echo "📦 Step 5: Building and starting containers..."
docker-compose up -d

echo ""
echo "⏱️  Waiting for services to be ready (30 seconds)..."
sleep 30

echo ""
echo "📦 Step 6: Checking service status..."
docker-compose ps

echo ""
echo "════════════════════════════════════════════════════════════════════════════════"
echo "✨ DEPLOYMENT COMPLETE!"
echo "════════════════════════════════════════════════════════════════════════════════"
echo ""

# Get IP and show access info
IP=$(hostname -I | awk '{print $1}')

echo "🌐 ACCESS YOUR SYSTEM:"
echo ""
echo "   API Docs:        http://150.95.84.201:8000/docs"
echo "   Database Admin:  http://150.95.84.201:5050"
echo "   REST API:        http://150.95.84.201:8000"
echo ""

echo "💾 DATABASE CREDENTIALS:"
echo "   Username: paymentuser"
echo "   Password: PaymentSecure2024"
echo "   Database: payment_db"
echo ""

echo "📋 Verify database connection:"
docker-compose exec db psql -U paymentuser -d payment_db -c "SELECT 'Database Connected!' as status;"

echo ""
echo "════════════════════════════════════════════════════════════════════════════════"
echo "🎉 System is now LIVE!"
echo "════════════════════════════════════════════════════════════════════════════════"
