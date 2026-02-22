#!/bin/bash

# PromptPay System - Interactive VPS Deployment
# This script guides you through the deployment process step by step

echo ""
echo "════════════════════════════════════════════════════════════════════════════════"
echo "🚀 PROMPTPAY SYSTEM - INTERACTIVE VPS DEPLOYMENT"
echo "════════════════════════════════════════════════════════════════════════════════"
echo ""

# Configuration
VPS_IP="150.95.84.201"
VPS_USER="root"
VPS_PATH="/opt/promptpay-system"

echo "📝 VPS Details:"
echo "   Host: $VPS_IP"
echo "   User: $VPS_USER"
echo "   Path: $VPS_PATH"
echo ""

# Step 1: Check local files
echo "📋 STEP 1: Verifying local files..."
echo ""

FILES_NEEDED=(
    "main.py"
    "models.py"
    "qr_reader.py"
    "payment_service.py"
    "schemas.py"
    "database.py"
    "config.py"
    "Dockerfile"
    "docker-compose.yml"
    "requirements.txt"
    "setup.sh"
    "DEPLOY_TO_VPS.sh"
)

missing=0
for file in "${FILES_NEEDED[@]}"; do
    if [ -f "$file" ]; then
        echo "   ✅ $file"
    else
        echo "   ❌ $file (MISSING!)"
        ((missing++))
    fi
done

echo ""
if [ $missing -gt 0 ]; then
    echo "❌ ERROR: $missing files are missing!"
    echo "   Make sure you're in the /workspaces/slip directory"
    exit 1
fi

echo "✅ All files present"
echo ""

# Step 2: Create remote directory
echo "════════════════════════════════════════════════════════════════════════════════"
echo "📤 STEP 2: Creating remote directory on VPS..."
echo "════════════════════════════════════════════════════════════════════════════════"
echo ""

echo "🔑 You'll be asked for password now"
echo "   Password: Laline1812@"
echo ""
echo "Running command:"
echo "   ssh root@$VPS_IP \"mkdir -p $VPS_PATH\""
echo ""

ssh root@$VPS_IP "mkdir -p $VPS_PATH"

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ SSH connection failed!"
    echo "   Please check:"
    echo "   1. VPS is running"
    echo "   2. SSH port 22 is open"
    echo "   3. Credentials are correct"
    exit 1
fi

echo ""
echo "✅ Remote directory ready"
echo ""

# Step 3: Upload files
echo "════════════════════════════════════════════════════════════════════════════════"
echo "📤 STEP 3: Uploading files to VPS..."
echo "════════════════════════════════════════════════════════════════════════════════"
echo ""

uploaded=0
failed=0

for file in main.py models.py qr_reader.py payment_service.py schemas.py database.py config.py Dockerfile docker-compose.yml requirements.txt setup.sh DEPLOY_TO_VPS.sh README.md API_REFERENCE.md IMPLEMENTATION_GUIDE.md DEPLOYMENT_GUIDE.md ARCHITECTURE.md DELIVERY_SUMMARY.md VPS_DEPLOYMENT_GUIDE.md QUICK_DEPLOY.md; do
    if [ -f "$file" ]; then
        echo -n "   Uploading $file... "
        if scp -q "$file" root@$VPS_IP:$VPS_PATH/ 2>/dev/null; then
            echo "✅"
            ((uploaded++))
        else
            echo "❌"
            ((failed++))
        fi
    fi
done

echo ""
echo "📊 Upload Summary:"
echo "   ✅ Uploaded: $uploaded files"
if [ $failed -gt 0 ]; then
    echo "   ❌ Failed: $failed files"
fi

echo ""

# Step 4: Run deployment on VPS
echo "════════════════════════════════════════════════════════════════════════════════"
echo "🚀 STEP 4: Starting deployment on VPS..."
echo "════════════════════════════════════════════════════════════════════════════════"
echo ""

echo "Connecting to VPS and running deployment script..."
echo "This will install Docker, PostgreSQL, and start the system..."
echo ""

ssh root@$VPS_IP "cd $VPS_PATH && chmod +x DEPLOY_TO_VPS.sh && ./DEPLOY_TO_VPS.sh"

echo ""
echo "════════════════════════════════════════════════════════════════════════════════"
echo "✅ DEPLOYMENT COMPLETE"
echo "════════════════════════════════════════════════════════════════════════════════"
echo ""

# Step 5: Verification
echo "🔍 STEP 5: Verifying deployment..."
echo ""

echo "Checking services on VPS..."
ssh root@$VPS_IP "cd $VPS_PATH && docker-compose ps"

echo ""
echo "════════════════════════════════════════════════════════════════════════════════"
echo "✨ YOUR SYSTEM IS LIVE!"
echo "════════════════════════════════════════════════════════════════════════════════"
echo ""

echo "🌐 ACCESS YOUR SYSTEM:"
echo ""
echo "   API Documentation:     http://150.95.84.201:8000/docs"
echo "   Database Admin (pgAdmin): http://150.95.84.201:5050"
echo "   REST API:               http://150.95.84.201:8000"
echo ""

echo "💾 DATABASE CREDENTIALS:"
echo "   Username: paymentuser"
echo "   Password: PaymentSecure2024"
echo "   Database: payment_db"
echo ""

echo "🧪 TEST THE SYSTEM:"
echo ""
echo "   curl -X POST http://150.95.84.201:8000/api/payment/generate-qr -H \"Content-Type: application/json\" -d '{\"account_id\":\"004999012726757\",\"amount\":1500.50}'"
echo ""

echo "⚠️  IMPORTANT:"
echo "   1. Change database password (in /opt/promptpay-system/.env)"
echo "   2. Change root VPS password"
echo "   3. Set up HTTPS/SSL certificate"
echo "   4. Configure firewall rules"
echo ""

echo "════════════════════════════════════════════════════════════════════════════════"
