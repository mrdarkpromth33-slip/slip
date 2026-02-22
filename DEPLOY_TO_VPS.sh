#!/bin/bash

# PromptPay Payment System - VPS Deployment Script
# Run this on your VPS to deploy the system automatically

set -e

echo "════════════════════════════════════════════════════════════════"
echo "🚀 PromptPay Payment System - VPS Deployment"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "❌ This script must be run as root"
   exit 1
fi

echo "📦 Step 1: Update system packages"
apt-get update && apt-get upgrade -y

echo "📦 Step 2: Install Docker"
apt-get install -y docker.io

echo "📦 Step 3: Install Docker Compose"
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

echo "📦 Step 4: Start Docker service"
systemctl start docker
systemctl enable docker

echo "📦 Step 5: Create deployment directory"
mkdir -p /opt/promptpay-system
cd /opt/promptpay-system

echo "📦 Step 6: Download system files (you need to upload them)"
echo "   Note: Copy all project files to /opt/promptpay-system/"
echo ""

echo "📦 Step 7: Create environment file"
cat > .env << 'ENVFILE'
# Database Configuration
DATABASE_URL=postgresql://paymentuser:PaymentSecure2024@db:5432/payment_db
DB_USER=paymentuser
DB_PASSWORD=PaymentSecure2024
DB_NAME=payment_db

# API Configuration
PROJECT_NAME=PromptPay Payment System
API_PREFIX=/api
DEBUG=false

# Security
ALLOWED_HOSTS=*
SECRET_KEY=your-secure-secret-key-change-this
ENVFILE

echo "✅ Environment file created"
echo ""

echo "📦 Step 8: Deploy with Docker Compose"
if [ -f "docker-compose.yml" ]; then
    docker-compose up -d
    echo "✅ Docker containers started"
else
    echo "❌ docker-compose.yml not found!"
    echo "   Please upload all project files first"
    exit 1
fi

echo ""
echo "📦 Step 9: Wait for services to be ready"
sleep 10

echo "📦 Step 10: Verify services"
docker-compose ps

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✅ DEPLOYMENT COMPLETE"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "📊 System Status:"
docker-compose ps

echo ""
echo "🌐 Access your system at:"
echo "  • API: http://150.95.84.201:8000"
echo "  • Swagger Docs: http://150.95.84.201:8000/docs"
echo "  • pgAdmin: http://150.95.84.201:5050"
echo ""

echo "📝 Next steps:"
echo "  1. Change database password (in .env and pgAdmin)"
echo "  2. Set up SSL certificate (Let's Encrypt recommended)"
echo "  3. Configure firewall rules"
echo "  4. Monitor logs: docker-compose logs -f"
echo ""

echo "🔑 Important: Change these after deployment:"
echo "  • DB_PASSWORD in .env"
echo "  • SECRET_KEY in .env"
echo "  • Root VPS password"
echo ""

echo "✨ System ready! PromptPay payment system is now live 🎉"
