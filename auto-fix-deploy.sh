#!/bin/bash

# Auto-fix deployment on VPS
# This script connects to VPS and fixes the Docker issue

VPS="root@150.95.84.201"
VPS_PATH="/opt/promptpay-system"

echo ""
echo "════════════════════════════════════════════════════════════════════════════════"
echo "🔧 AUTO FIX & DEPLOY TO VPS"
echo "════════════════════════════════════════════════════════════════════════════════"
echo ""

# Upload the fix script
echo "📤 Uploading fix script to VPS..."
scp -q fix-and-deploy.sh $VPS:$VPS_PATH/

if [ $? -ne 0 ]; then
    echo "❌ Failed to upload fix script"
    exit 1
fi

echo "✅ Fix script uploaded"
echo ""

# Run the fix script
echo "🚀 Running fix and deploy on VPS..."
echo "   (This will take 10-15 minutes)"
echo ""

ssh $VPS "cd $VPS_PATH && chmod +x fix-and-deploy.sh && bash fix-and-deploy.sh"

echo ""
echo "════════════════════════════════════════════════════════════════════════════════"
echo "✅ FIX & DEPLOY COMPLETE"
echo "════════════════════════════════════════════════════════════════════════════════"
echo ""

echo "🌐 Your system is ready at:"
echo "   http://150.95.84.201:8000/docs"
echo ""
