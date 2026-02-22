#!/bin/bash

echo "Checking PromptPay services status on VPS..."
echo "============================================"

# Check Docker containers
echo "📦 Docker containers:"
ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@150.95.84.201 'docker ps -a --format "table {{.Names}}\t{{.Status}}"' 2>/dev/null || echo "⚠️  Unable to check containers"

echo ""
echo "🔗 Testing API connectivity..."
# Test if API is responding
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://150.95.84.201:8000/docs 2>/dev/null || echo "000")
if [ "$RESPONSE" = "200" ]; then
    echo "✅ API is accessible: http://150.95.84.201:8000/docs"
else
    echo "⏳ API still initializing (HTTP $RESPONSE)... checking in 5 seconds"
    sleep 5
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://150.95.84.201:8000/docs 2>/dev/null || echo "000")
    if [ "$RESPONSE" = "200" ]; then
        echo "✅ API is now accessible: http://150.95.84.201:8000/docs"
    else
        echo "⚠️  API still initializing"
    fi
fi

echo ""
echo "📊 Quick test - Generate QR Code:"
RESULT=$(curl -s -X POST http://150.95.84.201:8000/api/payment/generate-qr \
  -H "Content-Type: application/json" \
  -d '{"amount": 100}' 2>/dev/null)

if echo "$RESULT" | grep -q "qr_code\|qr_image"; then
    echo "✅ QR generation working!"
    echo "Response: $(echo $RESULT | head -c 100)..."
else
    echo "⚠️  Still initializing or API not responding yet"
    echo "Raw response: $RESULT" | head -c 150
fi

echo ""
echo "============================================"
