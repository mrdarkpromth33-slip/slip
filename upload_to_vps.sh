#!/bin/bash

# Helper script to upload project files to VPS
# Usage: ./upload_to_vps.sh

VPS_IP="150.95.84.201"
VPS_USER="root"
VPS_PATH="/opt/promptpay-system"

echo "════════════════════════════════════════════════════════════════"
echo "📤 Upload PromptPay System to VPS"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Check if SSH connection is available
echo "🔌 Testing SSH connection..."
if ssh -o ConnectTimeout=5 root@$VPS_IP "echo 'Connected' > /dev/null 2>&1"; then
    echo "✅ SSH connection successful"
else
    echo "⚠️  SSH connection test failed"
    echo "   Using scp with password prompt..."
fi

echo ""
echo "📋 Files to upload:"
echo "  ├─ Python code (main.py, models.py, etc.)"
echo "  ├─ Docker files (Dockerfile, docker-compose.yml)"
echo "  ├─ Config files (requirements.txt, config.py)"
echo "  ├─ Documentation"
echo "  └─ Slip image example"

echo ""
echo "📤 Creating remote directory..."
ssh root@$VPS_IP "mkdir -p $VPS_PATH" || echo "⚠️  Directory already exists"

echo ""
echo "📤 Uploading files..."

# Upload Python code
echo "  • Uploading Python code..."
scp main.py root@$VPS_IP:$VPS_PATH/
scp models.py root@$VPS_IP:$VPS_PATH/
scp qr_reader.py root@$VPS_IP:$VPS_PATH/
scp payment_service.py root@$VPS_IP:$VPS_PATH/
scp schemas.py root@$VPS_IP:$VPS_PATH/
scp database.py root@$VPS_IP:$VPS_PATH/
scp config.py root@$VPS_IP:$VPS_PATH/

# Upload Docker files
echo "  • Uploading Docker configuration..."
scp Dockerfile root@$VPS_IP:$VPS_PATH/
scp docker-compose.yml root@$VPS_IP:$VPS_PATH/

# Upload requirements
echo "  • Uploading requirements..."
scp requirements.txt root@$VPS_IP:$VPS_PATH/

# Upload deployment scripts
echo "  • Uploading deployment scripts..."
scp DEPLOY_TO_VPS.sh root@$VPS_IP:$VPS_PATH/
scp setup.sh root@$VPS_IP:$VPS_PATH/

# Upload documentation
echo "  • Uploading documentation..."
scp README.md root@$VPS_IP:$VPS_PATH/
scp API_REFERENCE.md root@$VPS_IP:$VPS_PATH/
scp IMPLEMENTATION_GUIDE.md root@$VPS_IP:$VPS_PATH/
scp DEPLOYMENT_GUIDE.md root@$VPS_IP:$VPS_PATH/
scp VPS_DEPLOYMENT_GUIDE.md root@$VPS_IP:$VPS_PATH/
scp ARCHITECTURE.md root@$VPS_IP:$VPS_PATH/
scp DELIVERY_SUMMARY.md root@$VPS_IP:$VPS_PATH/

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✅ Upload Complete"
echo "════════════════════════════════════════════════════════════════"
echo ""

echo "📝 Next steps:"
echo ""
echo "1. SSH into VPS:"
echo "   ssh root@$VPS_IP"
echo ""
echo "2. Navigate to directory:"
echo "   cd $VPS_PATH"
echo ""
echo "3. Run deployment script:"
echo "   chmod +x DEPLOY_TO_VPS.sh"
echo "   ./DEPLOY_TO_VPS.sh"
echo ""
echo "4. Access your system:"
echo "   • API: http://$VPS_IP:8000"
echo "   • Docs: http://$VPS_IP:8000/docs"
echo "   • pgAdmin: http://$VPS_IP:5050"
echo ""

echo "✨ Done!"
