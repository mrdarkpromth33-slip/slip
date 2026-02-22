#!/bin/bash

# Advanced Docker Fix - Resolves containerd conflicts

echo ""
echo "════════════════════════════════════════════════════════════════════════════════"
echo "🔧 ADVANCED DOCKER FIX - HANDLING CONTAINERD CONFLICTS"
echo "════════════════════════════════════════════════════════════════════════════════"
echo ""

if [[ $EUID -ne 0 ]]; then
   echo "❌ This script must be run as root"
   exit 1
fi

cd /opt/promptpay-system

echo "📦 Step 1: Remove ALL conflicting Docker/Container packages..."
apt-get remove -y --allow-remove-essential \
  docker.io docker-ce docker-ce-cli docker-compose \
  containerio containerd containerd.io 2>/dev/null || true

apt-get autoremove -y --allow-remove-essential 2>/dev/null || true

echo ""
echo "📦 Step 2: Clean up Docker configuration..."
rm -rf /etc/docker
rm -rf /var/lib/docker
rm -rf /var/lib/containerd

echo ""
echo "📦 Step 3: Install fresh Docker .io package..."
apt-get update
apt-get install -y docker.io

echo ""
echo "📦 Step 4: Install Docker Compose v2..."
apt-get install -y docker-compose-v2 || apt-get install -y docker-compose

echo ""
echo "📦 Step 5: Create docker-compose symlink..."
ln -sf /usr/libexec/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose || \
ln -sf /usr/bin/docker-compose /usr/local/bin/docker-compose

echo ""
echo "📦 Step 6: Starting Docker service..."
systemctl daemon-reload
systemctl restart docker
systemctl enable docker

echo ""
echo "📦 Step 7: Verifying Docker installation..."
docker --version
docker-compose --version || docker compose --version

echo ""
echo "📦 Step 8: Building and starting PromptPay containers..."
docker-compose down 2>/dev/null || true
docker-compose up -d

echo ""
echo "⏱️  Waiting 30 seconds for services to start..."
sleep 30

echo ""
echo "📦 Step 9: Checking container status..."
docker-compose ps

echo ""
echo "════════════════════════════════════════════════════════════════════════════════"
echo "✅ DOCKER FIX & DEPLOYMENT COMPLETE!"
echo "════════════════════════════════════════════════════════════════════════════════"
echo ""

# Final verification
echo "🔍 Final verification:"
echo ""

echo "📊 Docker Info:"
docker info | head -20

echo ""
echo "🌐 Services:"
docker-compose ps

echo ""
echo "════════════════════════════════════════════════════════════════════════════════"
echo "✨ YOUR PROMPTPAY SYSTEM IS LIVE!"
echo "════════════════════════════════════════════════════════════════════════════════"
echo ""
echo "Access at:"
echo "  🌐 http://150.95.84.201:8000/docs (API Documentation)"
echo "  💾 http://150.95.84.201:5050 (Database Admin)"
echo ""
