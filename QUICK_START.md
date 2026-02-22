# Quick Start Guide - PromptPay Payment System

## ⚡ 5-Minute Setup

### Prerequisites
- Python 3.8+
- Docker & Docker Compose (or PostgreSQL 12+)
- Git

### Step 1: Clone & Enter Directory
```bash
cd /workspaces/slip
```

### Step 2: Run Setup Script
```bash
bash setup.sh
```

This will:
- ✅ Create Python virtual environment
- ✅ Install all dependencies
- ✅ Start PostgreSQL with Docker Compose
- ✅ Verify everything is ready

### Step 3: Start the Server
```bash
# Activate virtual environment first
source venv/bin/activate

# Run FastAPI server
python main.py
```

Server will be available at: **http://localhost:8000**

### Step 4: Test the API
```bash
bash test_api.sh
```

Or visit:
- 📖 API Docs: http://localhost:8000/docs
- 📘 ReDoc: http://localhost:8000/redoc
- ✅ Health: http://localhost:8000/health

---

## 📋 Basic Workflow Test

### 1️⃣ Generate QR Code
```bash
curl -X POST "http://localhost:8000/api/payment/generate-qr" \
  -H "Content-Type: application/json" \
  -d '{
    "order_id": "TEST123",
    "amount": 500.00
  }'
```

**Response:**
```json
{
  "order_id": "TEST123",
  "amount": 500.45,
  "qr_payload": "00020...",
  "created_at": "2024-01-15T10:30:00"
}
```

### 2️⃣ Simulate Payment Notification (from Android App)
```bash
curl -X POST "http://localhost:8000/api/webhook/linebk" \
  -H "Content-Type: application/json" \
  -d '{
    "app": "LINE",
    "title": "LINE BK",
    "text": "เงินเข้า 500.45 บาท เวลา 10:35",
    "timestamp": 1705318500
  }'
```

**Response:**
```json
{
  "success": true,
  "message": "Notification received and recorded",
  "transaction_id": 1
}
```

### 3️⃣ Check Order Status
```bash
curl "http://localhost:8000/api/orders/TEST123"
```

**Response:**
```json
{
  "id": 1,
  "order_id": "TEST123",
  "amount": 500.45,
  "status": "pending",
  "created_at": "2024-01-15T10:30:00",
  "updated_at": "2024-01-15T10:30:00"
}
```

### 4️⃣ Upload Slip (with QR code in image)
```bash
# Create a test image with embedded QR (in real scenario, user uploads actual slip)
curl -X POST "http://localhost:8000/api/payment/upload-slip?order_id=TEST123" \
  -F "file=@slip_image.jpg"
```

**Response (on success):**
```json
{
  "success": true,
  "message": "Payment verified successfully",
  "ref_id": "1705318500_50045",
  "bank_id": "KBANK",
  "matched_order_id": 1,
  "order_status": "completed"
}
```

### 5️⃣ Verify Order Completed
```bash
curl "http://localhost:8000/api/orders/TEST123"
```

**Response:**
```json
{
  "id": 1,
  "order_id": "TEST123",
  "amount": 500.45,
  "status": "completed",
  "created_at": "2024-01-15T10:30:00",
  "updated_at": "2024-01-15T10:35:00"
}
```

---

## � 100% Strict Verification (NEW!)

**Payment verification now uses 5-layer security:**
1. ✅ QR Code detection (required)
2. ✅ Amount extraction (QR + OCR)
3. ✅ **STRICT matching** (must be exact, no tolerance)
4. ✅ Duplicate detection
5. ✅ Cross-verification + audit trail

[Full Details →](STRICT_VERIFICATION.md)

---

## 🐛 Troubleshooting Quick Tips

| Issue | Solution |
|-------|----------|
| `psycopg2.OperationalError` | PostgreSQL not running. Run `docker-compose up -d` |
| `ModuleNotFoundError` | Virtual environment not activated. Run `source venv/bin/activate` |
| QR not reading | Upload high-quality image (>600x600px) with clear QR |
| Port 8000 already in use | Kill process: `lsof -i :8000` then `kill -9 <PID>` |
| Database tables missing | Tables auto-create on first run. Check console for errors |
| OCR Error: TesseractNotFoundError | Install tesseract: `sudo apt install tesseract-ocr` |

---

## 📂 Project Structure
```
slip/
├── main.py                    # FastAPI application + all endpoints
├── models.py                  # SQLAlchemy ORM models (Order, Transaction)
├── schemas.py                 # Pydantic request/response schemas
├── database.py                # Database connection setup
├── config.py                  # Configuration (from .env)
├── payment_service.py         # PromptPay QR generation & amount extraction
├── qr_reader.py              # QR code reading from slip images
├── requirements.txt           # Python dependencies
├── Dockerfile                # Docker configuration
├── docker-compose.yml        # PostgreSQL + App containers
├── .env                      # Environment variables
├── .gitignore               # Git ignore rules
├── setup.sh                 # Automated setup script
├── test_api.sh              # API testing script
├── IMPLEMENTATION_GUIDE.md  # Detailed API documentation
├── INTEGRATION_GUIDE.md     # Frontend/Android integration
└── QUICK_START.md          # This file
```

---

## 🚀 Next Steps After Setup

1. **Read Documentation**
   - [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md) - Full API details
   - [INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md) - Frontend/Android examples

2. **Integrate with Your Frontend**
   - See JavaScript examples in INTEGRATION_GUIDE.md
   - Use `/api/payment/generate-qr` to create QR codes
   - Implement polling with `/api/orders/{order_id}`

3. **Setup Android Notification Listener**
   - See Kotlin examples in INTEGRATION_GUIDE.md
   - Point webhook to `/api/webhook/linebk`

4. **Deploy to Production**
   - Update `.env` with real database credentials
   - Use Docker Compose: `docker-compose -f docker-compose.yml up -d`
   - Configure reverse proxy (nginx/Apache)
   - Setup SSL/TLS certificates

---

## 💡 Key Features

✅ **PromptPay EMVCo Standard QR Codes**
- Generated as per Thailand payment standard
- Support for decimal precision

✅ **Micro-transaction Decimal Addition**
- Automatic 0.01-0.99 baht addition
- Prevents order matching confusion

✅ **Multi-channel Verification**
- Webhook from Android (notification)
- QR reading from slip image
- Amount matching validation

✅ **Production Ready**
- PostgreSQL for data persistence
- Docker containerization
- Comprehensive error handling
- API documentation (Swagger/ReDoc)

---

## 📞 Support Resources

- **API Documentation**: http://localhost:8000/docs (when running)
- **Database Admin**: http://localhost:5050 (pgAdmin - when using docker-compose)
- **Logs**: Check console output or set `DEBUG=True` in .env

---

## 🔄 Development Workflow

```bash
# 1. Install dependencies
pip install -r requirements.txt

# 2. Start database
docker-compose up -d postgres

# 3. Run server with auto-reload
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# 4. Test endpoints
bash test_api.sh

# 5. Check database (pgAdmin)
# Visit http://localhost:5050

# 6. Stop services
docker-compose down
```

---

**Ready to go! Happy coding! 🎉**

For detailed information, see:
- [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md)
- [INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md)
