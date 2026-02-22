# PromptPay Payment System - Self-Hosted Backend

ระบบรับชำระเงิน PromptPay แบบ Self-hosted โดยอ่าน QR Code จากสลิปโอนเงิน พร้อมรองรับ Webhook จากแอปพลิเคชัน Android

## 🔐 100% STRICT VERIFICATION (NEW!)

ระบบตรวจสอบการโอนเงินแบบเข้มงวดสูงสุด:

**5-Layer Security:**
1. ✅ QR Code Detection (จำเป็น)
2. ✅ Amount Extraction (QR + OCR)
3. ✅ **STRICT Matching** (ต้องตรง 100% ไม่ยอม ±0.01)
4. ✅ Duplicate Detection (ไม่ให้ใช้สลิปซ้ำ)
5. ✅ Audit Trail Logging (บันทึกทุกอย่าง)

[📖 Full Documentation →](STRICT_VERIFICATION.md)

---

## 🎯 ลักษณะระบบ (System Architecture)

### Workflow
1. **Website → Backend**: ลูกค้าสั่งซื้อ → API สร้าง QR Code PromptPay
2. **Website → Customer**: แสดง QR Code ให้ลูกค้าสแกนจ่าย
3. **Android App → Backend**: ดักจับ Notification จาก LINE BK ส่ง Webhook → Backend บันทึกยอดเงิน
4. **Customer → Website**: อัปโหลดสลิปโอนเงิน
5. **Backend**: อ่าน QR จากสลิป ตรวจสอบและจับคู่กับ Order → อัปเดตสถานะเป็น Completed

## 📋 API Endpoints

### 1️⃣ Generate QR Code
```
POST /api/payment/generate-qr
Content-Type: application/json

{
  "order_id": "ORD001",
  "amount": 100.00
}

Response:
{
  "order_id": "ORD001",
  "amount": 100.01,  # Note: with micro-transaction (random cent)
  "qr_payload": "00020...",  # EMVCo format
  "qr_raw_data": "00020...",
  "created_at": "2024-01-01T12:00:00"
}
```

### 2️⃣ Receive LINE Bank Webhook
```
POST /api/webhook/linebk
Content-Type: application/json

{
  "app": "LINE",
  "title": "LINE BK",
  "text": "เงินเข้า 100.50 บาท เวลา 12:00",
  "timestamp": 1678888888
}

Response:
{
  "success": true,
  "message": "Notification received and recorded",
  "transaction_id": 1
}
```

### 3️⃣ Upload Slip & Verify Payment
```
POST /api/payment/upload-slip
Content-Type: multipart/form-data

file: <image_file>
order_id: ORD001 (optional - will match by amount if not provided)

Response:
{
  "success": true,
  "message": "Payment verified successfully",
  "ref_id": "1678888888_10050",
  "bank_id": "KBANK",
  "matched_order_id": 1,
  "order_status": "completed"
}
```

### 4️⃣ Query Endpoints (Testing)
```
GET /api/orders/{order_id}
GET /api/transactions/{ref_id}
GET /api/info
GET /health
```

## 🛠️ Tech Stack

- **Framework**: FastAPI (Python)
- **Database**: PostgreSQL 15
- **QR Reading**: pyzbar, opencv-python
- **Payment**: PromptPay EMVCo standard
- **ORM**: SQLAlchemy 2.0

## 📦 Installation

### Prerequisites
- Python 3.8+
- PostgreSQL 12+
- Docker & Docker Compose (optional, for local database)

### Step 1: Clone Repository
```bash
cd /workspaces/slip
```

### Step 2: Create Virtual Environment
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

### Step 3: Install Dependencies
```bash
pip install -r requirements.txt
```

### Step 4: Setup Database

#### Option A: Using Docker Compose (Recommended for Development)
```bash
docker-compose up -d
# Wait for PostgreSQL to be ready (check health logs)
docker-compose logs postgres
```

#### Option B: Manual PostgreSQL Setup
```sql
CREATE USER slip_user WITH PASSWORD 'slip_password';
CREATE DATABASE slip_db OWNER slip_user;
GRANT ALL PRIVILEGES ON DATABASE slip_db TO slip_user;
```

Then update `DATABASE_URL` in `.env`:
```bash
DATABASE_URL=postgresql://slip_user:slip_password@localhost:5432/slip_db
```

### Step 5: Run the Application
```bash
python main.py
# Or with uvicorn directly:
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Server will start at: **http://localhost:8000**

## 📚 API Documentation

Once the server is running, visit:
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

## 🧪 Testing

### Test QR Code Generation
```bash
curl -X POST "http://localhost:8000/api/payment/generate-qr" \
  -H "Content-Type: application/json" \
  -d '{"order_id": "TEST001", "amount": 150.00}'
```

### Test Webhook Reception
```bash
curl -X POST "http://localhost:8000/api/webhook/linebk" \
  -H "Content-Type: application/json" \
  -d '{
    "app": "LINE",
    "title": "LINE BK",
    "text": "เงินเข้า 150.00 บาท เวลา 14:30",
    "timestamp": 1678888888
  }'
```

### Test Slip Upload (with dummy image)
```bash
curl -X POST "http://localhost:8000/api/payment/upload-slip?order_id=TEST001" \
  -F "file=@path/to/slip_image.jpg"
```

## 📊 Database Schema

### Table: orders
| Column | Type | Notes |
|--------|------|-------|
| id | INTEGER | Primary Key |
| order_id | VARCHAR(100) | Unique order identifier |
| amount | FLOAT | Amount with micro-transaction (e.g., 100.01) |
| status | ENUM | pending \| completed \| failed \| expired |
| created_at | DATETIME | Order creation time |
| updated_at | DATETIME | Last update time |

### Table: transactions
| Column | Type | Notes |
|--------|------|-------|
| id | INTEGER | Primary Key |
| ref_id | VARCHAR(255) | Bank transaction reference (Unique) |
| amount | FLOAT | Amount received |
| bank_id | VARCHAR(50) | Sending bank identifier |
| status | ENUM | pending_slip \| matched \| verified \| failed |
| matched_order_id | FK → orders.id | Matched order |
| notification_text | VARCHAR(500) | Original notification text |
| slip_image_path | VARCHAR(255) | Uploaded slip file path |
| created_at | DATETIME | Transaction record creation |
| updated_at | DATETIME | Last update time |

## ⚙️ Configuration

Edit `.env` to change:
- `DATABASE_URL`: PostgreSQL connection string
- `HOST`: Server host (default: 0.0.0.0)
- `PORT`: Server port (default: 8000)
- `DEBUG`: Debug mode (True/False)

## 🔐 Important Features

### 1. Micro-transaction (Decimal Precision)
Each generated QR receives a **random cent value** (0.01 - 0.99) automatically added to prevent ambiguity when multiple orders have the same amount:
```
Order Amount: 100.00 → Generated: 100.45 บาท
```

### 2. Notification Reliability
- Primary method: QR code reading from slip (most reliable)
- Secondary: LINE Bank webhook notification (for reference)
- The system validates both before marking order as completed

### 3. Transaction Matching Logic
```
1. Read QR from slip image
2. Extract ref_id and bank_id
3. Match with webhook notification (if exists)
4. Match with order amount (within tolerance ±0.01)
5. Update both order and transaction status
```

## 📝 Development Notes

### Adding New Endpoints
1. Create schema in `schemas.py`
2. Add business logic in appropriate service file
3. Add endpoint in `main.py`
4. Update database models if needed

### Extending QR Reading
The `qr_reader.py` supports:
- Multiple QR code detection
- Image preprocessing (contrast, threshold, inversion)
- EMVCo format parsing
- Batch QR reading

### Android App Integration
Send webhook payload from Android app:
```json
{
  "app": "LINE",
  "title": "LINE BK",
  "text": "เงินเข้า 100.50 บาท เวลา 12:00",
  "timestamp": 1234567890
}
```

## 🐛 Troubleshooting

### PostgreSQL Connection Error
```
Error: could not connect to server
```
→ Check if PostgreSQL is running and `.env` DATABASE_URL is correct

### QR Code Not Reading
→ Try uploading high-quality slip image (>600x600px)
→ Ensure QR code is clearly visible and not damaged

### Micro-transaction Mismatch
→ System automatically adds cents to prevent duplicates
→ Query `/api/orders/{order_id}` to see exact amount

## 📞 Support

For issues or questions:
1. Check API documentation at `/docs`
2. Review database logs: `docker-compose logs postgres`
3. Check application logs in console output

## 📄 License

Developed for PromptPay payment processing

## 🚀 Next Steps

### Phase 2 Features (Future):
- [ ] WebSocket support for real-time payment status
- [ ] Email/SMS notifications
- [ ] Refund handling
- [ ] Admin dashboard
- [ ] Multiple merchant accounts
- [ ] Payment reconciliation reports
- [ ] Webhook retry mechanism
- [ ] Payment timeout handling

---

**Version**: 1.0.0  
**Last Updated**: 2024
