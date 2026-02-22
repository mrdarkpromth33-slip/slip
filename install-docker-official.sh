#!/bin/bash

# Install Docker using official Docker installer script
# This bypasses apt package manager conflicts with existing containerd

set -e

echo "🔧 Installing Docker using official Docker installer..."
echo "=================================================="

# SSH into VPS and run Docker official install
ssh -o StrictHostKeyChecking=no root@150.95.84.201 << 'REMOTE_EOF'

# Step 1: Remove conflicting packages
echo "📦 Removing conflicting packages..."
apt-get update > /dev/null 2>&1 || true
apt-get remove -y docker-ce docker docker.io containerd 2>/dev/null || true
apt-get purge -y containerd 2>/dev/null || true
apt-get autoremove -y > /dev/null 2>&1 || true

# Step 2: Install dependencies
echo "📦 Installing dependencies..."
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    ubuntu-keyring > /dev/null 2>&1

# Step 3: Download and run official Docker installer
echo "📥 Downloading official Docker installer..."
curl -fsSL https://get.docker.com -o get-docker.sh
chmod +x get-docker.sh

echo "⚙️  Running Docker official installer..."
sh get-docker.sh

# Step 4: Install Docker Compose
echo "📥 Installing Docker Compose..."
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Step 5: Verify installations
echo ""
echo "✅ Checking Docker installation..."
docker --version

echo "✅ Checking Docker Compose installation..."
docker-compose --version

echo ""
echo "✅ Docker daemon status:"
systemctl status docker --no-pager || echo "Starting Docker..."
systemctl start docker || true
sleep 2

echo ""
echo "✅ Docker info:"
docker info --format='Server Version: {{.ServerVersion}}'

REMOTE_EOF

echo ""
echo "=================================================="
echo "✅ Docker installation complete!"
echo ""
echo "Next steps:"
echo "  1. cd /opt/promptpay-system"
echo "  2. docker-compose up -d"
echo "  3. Check http://150.95.84.201:8000/docs"
