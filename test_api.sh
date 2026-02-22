#!/bin/bash

# Test API Endpoints

BASE_URL="http://localhost:8000"
TIMESTAMP=$(date +%s)
RANDOM_ORDER="ORD$(date +%s%N | tail -c 9)"

echo "================================"
echo "PromptPay Payment System - API Tests"
echo "================================"
echo ""
echo "Base URL: $BASE_URL"
echo "Test Order ID: $RANDOM_ORDER"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test 1: Health Check
echo -e "${BLUE}[Test 1] Health Check${NC}"
curl -s "$BASE_URL/health" | python3 -m json.tool
echo ""

# Test 2: Generate QR Code
echo -e "${BLUE}[Test 2] Generate QR Code${NC}"
QR_RESPONSE=$(curl -s -X POST "$BASE_URL/api/payment/generate-qr" \
  -H "Content-Type: application/json" \
  -d "{
    \"order_id\": \"$RANDOM_ORDER\",
    \"amount\": 250.00
  }")
echo "$QR_RESPONSE" | python3 -m json.tool

# Extract amount for webhook test
AMOUNT=$(echo "$QR_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['amount'])" 2>/dev/null || echo "250.00")
echo -e "${GREEN}Generated amount: $AMOUNT${NC}"
echo ""

# Test 3: Receive LINE Bank Webhook
echo -e "${BLUE}[Test 3] Receive LINE Bank Webhook${NC}"
WEBHOOK_RESPONSE=$(curl -s -X POST "$BASE_URL/api/webhook/linebk" \
  -H "Content-Type: application/json" \
  -d "{
    \"app\": \"LINE\",
    \"title\": \"LINE BK\",
    \"text\": \"เงินเข้า $AMOUNT บาท เวลา 14:30\",
    \"timestamp\": $TIMESTAMP
  }")
echo "$WEBHOOK_RESPONSE" | python3 -m json.tool
echo ""

# Test 4: Query Order Status
echo -e "${BLUE}[Test 4] Query Order Status${NC}"
curl -s "$BASE_URL/api/orders/$RANDOM_ORDER" | python3 -m json.tool
echo ""

# Test 5: API Info
echo -e "${BLUE}[Test 5] API Information${NC}"
curl -s "$BASE_URL/api/info" | python3 -m json.tool
echo ""

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}All tests completed!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo "Note: To test slip upload, run:"
echo -e "  ${YELLOW}curl -X POST \"$BASE_URL/api/payment/upload-slip?order_id=$RANDOM_ORDER\" \\${NC}"
echo -e "  ${YELLOW}-F \"file=@path/to/slip_image.jpg\"${NC}"
echo ""
