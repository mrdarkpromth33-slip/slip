#!/bin/bash

# Auto-run advanced fix on VPS

echo ""
echo "════════════════════════════════════════════════════════════════════════════════"
echo "📤 AUTO-DEPLOYING ADVANCED FIX TO VPS"
echo "════════════════════════════════════════════════════════════════════════════════"
echo ""

VPS_HOST="150.95.84.201"
VPS_USER="root"
VPS_PATH="/opt/promptpay-system"

echo "📤 Uploading advanced fix script to VPS..."
scp -o StrictHostKeyChecking=no advanced-fix-deploy.sh ${VPS_USER}@${VPS_HOST}:${VPS_PATH}/

echo ""
echo "🚀 Running advanced fix on VPS (may take 15-20 minutes)..."
echo ""

ssh -o StrictHostKeyChecking=no ${VPS_USER}@${VPS_HOST} "bash ${VPS_PATH}/advanced-fix-deploy.sh"

echo ""
echo "════════════════════════════════════════════════════════════════════════════════"
echo "✅ ADVANCED FIX DEPLOYMENT COMPLETE"
echo "════════════════════════════════════════════════════════════════════════════════"
echo ""
