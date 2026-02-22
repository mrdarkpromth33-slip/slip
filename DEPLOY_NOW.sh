#!/bin/bash

# PromptPay VPS DEPLOYMENT - QUICK START
# Run this from your local machine to deploy to VPS

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "🚀 PROMPTPAY SYSTEM - QUICK VPS DEPLOYMENT"
echo "════════════════════════════════════════════════════════════════"
echo ""

VPS="root@150.95.84.201"
DEPLOY_PATH="/opt/promptpay-system"

# Step 1: Prepare upload script
echo "📋 Step 1: Setting up upload script..."
if [ ! -f "upload_to_vps.sh" ]; then
    echo "❌ upload_to_vps.sh not found!"
    exit 1
fi

chmod +x upload_to_vps.sh
echo "✅ Upload script ready"
echo ""

# Step 2: Show upload command
echo "📤 Step 2: Uploading files to VPS..."
echo "   (You will be asked for password: Laline1812@)"
echo ""

# Create directory on VPS
ssh $VPS "mkdir -p $DEPLOY_PATH" 2>/dev/null

# Upload files
FILES="main.py models.py qr_reader.py payment_service.py schemas.py database.py config.py Dockerfile docker-compose.yml requirements.txt setup.sh DEPLOY_TO_VPS.sh README.md API_REFERENCE.md IMPLEMENTATION_GUIDE.md DEPLOYMENT_GUIDE.md ARCHITECTURE.md DELIVERY_SUMMARY.md VPS_DEPLOYMENT_GUIDE.md"

count=0
for file in $FILES; do
    if [ -f "$file" ]; then
        scp -q "$file" "$VPS:$DEPLOY_PATH/" 2>/dev/null && ((count++))
    fi
done

echo "   ✅ Uploaded $count files"
echo ""

# Step 3: Show deployment commands
echo "════════════════════════════════════════════════════════════════"
echo "✨ UPLOAD COMPLETE"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "📝 Run these commands on VPS to deploy:"
echo ""
echo "  1. ssh root@150.95.84.201"
echo "  2. cd /opt/promptpay-system"
echo "  3. chmod +x DEPLOY_TO_VPS.sh"
echo "  4. ./DEPLOY_TO_VPS.sh"
echo ""
echo "After deployment, access at:"
echo "  • http://150.95.84.201:8000/docs"
echo ""
