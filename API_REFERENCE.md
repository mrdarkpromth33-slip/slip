# API Reference - PromptPay Payment System

## Base URL
```
http://localhost:8000
```

## Authentication
Currently no authentication required. Production deployment should add API keys or JWT tokens.

---

## 📡 Core Endpoints

### 1. Generate QR Code
Generate a PromptPay QR code for payment processing.

```http
POST /api/payment/generate-qr
Content-Type: application/json
```

**Request Body:**
```json
{
  "order_id": "string (1-100 chars)",
  "amount": "number (> 0)"
}
```

**Example Request:**
```json
{
  "order_id": "ORD-20240115-001",
  "amount": 1500.00
}
```

**Response (200 OK):**
```json
{
  "order_id": "ORD-20240115-001",
  "amount": 1500.47,
  "qr_payload": "00020112910126...",
  "qr_raw_data": "00020112910126...",
  "created_at": "2024-01-15T10:30:00Z"
}
```

**Response (400 Bad Request):**
```json
{
  "detail": [
    {
      "type": "value_error",
      "loc": ["body", "amount"],
      "msg": "ensure this value is greater than 0"
    }
  ]
}
```

**Response (500 Internal Error):**
```json
{
  "detail": "Failed to generate QR code: [error details]"
}
```

**Notes:**
- `amount` in response may differ from request due to automatic micro-transaction addition
- QR payload is in EMVCo format (PromptPay standard)
- Same `order_id` will return existing order (idempotent)

---

### 2. Receive LINE Bank Webhook
Receive payment notification from Android app (notification from LINE Bank).

```http
POST /api/webhook/linebk
Content-Type: application/json
```

**Request Body:**
```json
{
  "app": "string",           // "LINE" or other app name
  "title": "string",         // Notification title
  "text": "string",          // Notification text with amount
  "timestamp": "integer"     // Unix timestamp
}
```

**Example Request:**
```json
{
  "app": "LINE",
  "title": "LINE BK",
  "text": "เงินเข้า 1500.47 บาท เวลา 10:35:22",
  "timestamp": 1705318522
}
```

**Response (200 OK - New Notification):**
```json
{
  "success": true,
  "message": "Notification received and recorded",
  "transaction_id": 1
}
```

**Response (200 OK - Duplicate):**
```json
{
  "success": true,
  "message": "Transaction already recorded",
  "transaction_id": 1
}
```

**Response (200 OK - Amount Not Extracted):**
```json
{
  "success": false,
  "message": "Could not extract amount from notification",
  "transaction_id": null
}
```

**Response (500 Error):**
```json
{
  "detail": "Failed to process webhook: [error details]"
}
```

**Notes:**
- Amount is extracted using regex from Thai text
- Patterns recognized: "เงินเข้า X บาท", "X บาท", numeric values
- Duplicate notifications are ignored (using ref_id)
- Transaction status: `pending_slip` (waiting for slip upload)

**Supported Patterns:**
- ✅ "เงินเข้า 1500.47 บาท"
- ✅ "1500.47 บาท เข้ามา"
- ✅ "จำนวน 1500.47 บาท"
- ✅ "จากการโอน 1500.47 บาท"

---

### 3. Upload Slip & Verify Payment
Upload bank transfer slip image with QR code for verification.

```http
POST /api/payment/upload-slip
Content-Type: multipart/form-data
```

**Query Parameters:**
```
order_id: string (optional)  // If provided, matches this order directly
```

**Request Body:**
```
file: binary (required)      // Image file (jpg, png, etc.)
order_id: string (optional)  // Same as query parameter
```

**Example Request:**
```bash
curl -X POST "http://localhost:8000/api/payment/upload-slip?order_id=ORD-20240115-001" \
  -F "file=@slip_image.jpg"
```

**Response (200 OK - Payment Verified):**
```json
{
  "success": true,
  "message": "Payment verified successfully",
  "ref_id": "1705318522_150047",
  "bank_id": "KBANK",
  "matched_order_id": 1,
  "order_status": "completed"
}
```

**Response (200 OK - QR Not Found):**
```json
{
  "success": false,
  "message": "Could not read QR code from slip image",
  "ref_id": null,
  "bank_id": null,
  "matched_order_id": null,
  "order_status": null
}
```

**Response (200 OK - Transaction Not Found):**
```json
{
  "success": false,
  "message": "Transaction not found. Please check the QR code or transaction reference",
  "ref_id": null,
  "bank_id": null,
  "matched_order_id": null,
  "order_status": null
}
```

**Response (200 OK - Amount Not Matched):**
```json
{
  "success": false,
  "message": "Could not match payment to any order. Please check the amount",
  "ref_id": "1705318522_150047",
  "bank_id": "KBANK",
  "matched_order_id": null,
  "order_status": null
}
```

**Response (500 Error):**
```json
{
  "detail": "Failed to process slip: [error details]"
}
```

**Notes:**
- Requires high-quality image (≥600x600px recommended)
- QR code should be clearly visible and not damaged
- Amount matching tolerance: ±0.01 THB
- Updates order status to `completed` on success
- If multiple orders match amount, uses most recent one

**Image Requirements:**
- ✅ JPG, PNG, WebP, BMP
- ✅ 600x600px or larger
- ✅ Clear QR code visible
- ❌ Blurry, rotated (>45°), or damaged QR

---

## 📊 Query Endpoints

### 4. Get Order Status
Retrieve current status of an order.

```http
GET /api/orders/{order_id}
```

**Path Parameters:**
```
order_id: string (required)  // Order ID from generate-qr
```

**Example Request:**
```bash
curl "http://localhost:8000/api/orders/ORD-20240115-001"
```

**Response (200 OK):**
```json
{
  "id": 1,
  "order_id": "ORD-20240115-001",
  "amount": 1500.47,
  "status": "completed",
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-01-15T10:35:00Z"
}
```

**Response (404 Not Found):**
```json
{
  "detail": "Order ORD-20240115-001 not found"
}
```

**Status Values:**
- `pending` - Waiting for payment/slip verification
- `completed` - Payment verified and completed
- `failed` - Payment verification failed
- `expired` - Order expired (not yet implemented)

---

### 5. Get Transaction Status
Retrieve transaction details by reference ID.

```http
GET /api/transactions/{ref_id}
```

**Path Parameters:**
```
ref_id: string (required)  // Transaction reference from bank
```

**Example Request:**
```bash
curl "http://localhost:8000/api/transactions/1705318522_150047"
```

**Response (200 OK):**
```json
{
  "id": 1,
  "ref_id": "1705318522_150047",
  "amount": 1500.47,
  "bank_id": "KBANK",
  "status": "verified",
  "matched_order_id": 1,
  "created_at": "2024-01-15T10:32:00Z",
  "updated_at": "2024-01-15T10:35:00Z"
}
```

**Response (404 Not Found):**
```json
{
  "detail": "Transaction 1705318522_150047 not found"
}
```

**Status Values:**
- `pending_slip` - Waiting for slip upload/verification
- `matched` - Matched with webhook but not yet verified
- `verified` - QR read and verified successfully
- `failed` - Verification failed

---

## ℹ️ Information Endpoints

### 6. Get API Information
Get API metadata and endpoint list.

```http
GET /api/info
```

**Response (200 OK):**
```json
{
  "name": "PromptPay Payment System",
  "version": "1.0.0",
  "endpoints": [
    {
      "method": "POST",
      "path": "/api/payment/generate-qr",
      "description": "Generate PromptPay QR code"
    },
    {
      "method": "POST",
      "path": "/api/webhook/linebk",
      "description": "Receive LINE Bank notification webhook"
    },
    {
      "method": "POST",
      "path": "/api/payment/upload-slip",
      "description": "Upload slip image and verify payment"
    }
  ]
}
```

---

### 7. Health Check
Check if the API is running and database is connected.

```http
GET /health
```

**Response (200 OK):**
```json
{
  "status": "ok",
  "service": "PromptPay Payment System",
  "version": "1.0.0"
}
```

---

## 🔄 Typical Workflow

### Complete Payment Flow (Step by Step)

**Step 1: Generate QR**
```bash
# Customer makes order
curl -X POST "http://localhost:8000/api/payment/generate-qr" \
  -H "Content-Type: application/json" \
  -d '{
    "order_id": "ORD001",
    "amount": 500.00
  }'

# Response: QR with amount 500.45 (micro-tx added)
```

**Step 2: Customer Transfers (Simulated)**
```
Customer scans QR → Transfers 500.45 THB from bank
↓
LINE Bank sends notification to phone
```

**Step 3: Android App Sends Webhook**
```bash
curl -X POST "http://localhost:8000/api/webhook/linebk" \
  -H "Content-Type: application/json" \
  -d '{
    "app": "LINE",
    "title": "LINE BK",
    "text": "เงินเข้า 500.45 บาท เวลา 14:30",
    "timestamp": 1705318500
  }'

# Response: Transaction recorded (status: pending_slip)
```

**Step 4: Check Order Status**
```bash
curl "http://localhost:8000/api/orders/ORD001"

# Response: status = "pending" (waiting for slip verification)
```

**Step 5: Customer Uploads Slip**
```bash
curl -X POST "http://localhost:8000/api/payment/upload-slip?order_id=ORD001" \
  -F "file=@slip_image.jpg"

# Response: success = true, status = "completed"
```

**Step 6: Verify Completion**
```bash
curl "http://localhost:8000/api/orders/ORD001"

# Response: status = "completed" ✓
```

---

## 📋 Data Type Reference

### Enums

**OrderStatus**
```
pending      // Waiting for payment/slip
completed    // Payment verified
failed       // Payment failed
expired      // Order expired
```

**TransactionStatus**
```
pending_slip // Waiting for slip verification
matched      // Matched but not verified
verified     // Successfully verified
failed       // Verification failed
```

### Common Objects

**Order Object**
```json
{
  "id": "integer",                    // Internal ID
  "order_id": "string",               // Merchant order ID
  "amount": "number",                 // Amount with micro-tx
  "status": "OrderStatus",            // Current status
  "created_at": "ISO8601 datetime",   // Creation time
  "updated_at": "ISO8601 datetime"    // Last update
}
```

**Transaction Object**
```json
{
  "id": "integer",                    // Internal ID
  "ref_id": "string",                 // Bank transaction ref
  "amount": "number",                 // Transferred amount
  "bank_id": "string",                // Sending bank code
  "status": "TransactionStatus",      // Current status
  "matched_order_id": "integer",      // Matched order ID
  "created_at": "ISO8601 datetime",   // Record time
  "updated_at": "ISO8601 datetime"    // Last update
}
```

---

## ⚠️ Error Handling

### Common HTTP Status Codes

| Code | Meaning | When |
|------|---------|------|
| 200 | OK | Request successful |
| 400 | Bad Request | Invalid input data |
| 404 | Not Found | Order/transaction not found |
| 422 | Validation Error | Invalid request format |
| 500 | Server Error | Database error, file processing error |

### Error Response Format
```json
{
  "detail": "string description of error"
}
```

### Validation Errors (422)
```json
{
  "detail": [
    {
      "type": "error type",
      "loc": ["field", "path"],
      "msg": "error message"
    }
  ]
}
```

---

## 🔐 Security Considerations

### Current Implementation (Development)
- ✅ No authentication (add for production)
- ✅ Basic input validation
- ✅ SQL injection protection (SQLAlchemy ORM)
- ✅ File type validation (image only)

### Recommended for Production
- [ ] API Key authentication
- [ ] JWT tokens
- [ ] HTTPS/TLS
- [ ] CORS configuration
- [ ] Rate limiting
- [ ] Request signing
- [ ] Webhook signature verification

---

## 📝 Testing with cURL

### Test All Endpoints
```bash
#!/bin/bash

# Health check
curl http://localhost:8000/health

# Info
curl http://localhost:8000/api/info

# Generate QR
curl -X POST http://localhost:8000/api/payment/generate-qr \
  -H "Content-Type: application/json" \
  -d '{"order_id":"TEST001","amount":100.00}'

# Webhook
curl -X POST http://localhost:8000/api/webhook/linebk \
  -H "Content-Type: application/json" \
  -d '{
    "app":"LINE",
    "title":"LINE BK",
    "text":"เงินเข้า 100.50 บาท",
    "timestamp":1000000000
  }'

# Get order
curl http://localhost:8000/api/orders/TEST001

# Upload slip
curl -X POST http://localhost:8000/api/payment/upload-slip?order_id=TEST001 \
  -F "file=@slip.jpg"
```

---

## 🚀 Rate Limiting (Future)

Currently not implemented. For production, add:
```
- 100 requests per minute per IP
- 10 file uploads per hour per IP
- 1MB max file size
```

---

**API Version: 1.0.0**
**Last Updated: 2024-01-15**
