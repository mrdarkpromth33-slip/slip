# PromptPay Payment System - Self-Hosted Backend

[![Python](https://img.shields.io/badge/Python-3.8+-blue)](https://www.python.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.104+-green)](https://fastapi.tiangolo.com/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-blue)](https://www.postgresql.org/)
[![Docker](https://img.shields.io/badge/Docker-Supported-blue)](https://www.docker.com/)

**PromptPay Payment System** - A complete self-hosted backend solution for processing PromptPay payments with QR code reading from bank transfer slips and webhook integration for Android notifications.

## ✨ Key Features

✅ **PromptPay EMVCo Standard** - Generate compliant QR codes for Thailand payments  
✅ **QR Code Reading** - Read and parse QR codes from slip images using pyzbar + OpenCV  
✅ **Webhook Integration** - Receive payment notifications from Android apps  
✅ **Micro-transaction Support** - Automatic decimal addition for accurate order matching  
✅ **PostgreSQL Database** - Persistent transaction records with SQLAlchemy ORM  
✅ **RESTful API** - Comprehensive endpoints with Swagger/ReDoc documentation  
✅ **Docker Ready** - Production-ready containerization  
✅ **Mobile Friendly** - Designed for integration with Android notification listeners  

## 🎯 Use Cases

- 🛍️ E-commerce payment processing
- 🏪 Point-of-sale systems  
- 💳 Subscription/recurring payments
- 📱 Mobile app payment integration
- 🤝 B2B invoice payments

## 🚀 Quick Start (30 Seconds)

### 1. Prerequisites
- Docker & Docker Compose v2.0+
- 2GB RAM minimum
- 10GB disk space

### 2. Deploy
```bash
git clone https://github.com/mrdarkpromth33-slip/slip.git
cd slip
docker-compose up -d
```

### 3. Access System
```
API Docs:    http://localhost:8000/docs
Database:    http://localhost:5050 (admin@example.com / admin)
Swagger UI:  http://localhost:8000/redoc
```

**Full Setup Guide**: See [QUICK_START.md](QUICK_START.md)

## 📋 API Endpoints

| Method | Endpoint | Purpose |
|--------|----------|---------|
| `POST` | `/api/payment/generate-qr` | Generate PromptPay QR code |
| `POST` | `/api/webhook/linebk` | Receive payment notification |
| `POST` | `/api/payment/upload-slip` | Upload slip for verification |
| `GET` | `/api/orders/{order_id}` | Check order status |
| `GET` | `/api/info` | API information |

**Full API Docs**: See [API_REFERENCE.md](API_REFERENCE.md)

## 📚 Documentation

- [QUICK_START.md](QUICK_START.md) - 5-minute setup guide
- [API_REFERENCE.md](API_REFERENCE.md) - Detailed endpoint specs
- [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md) - Complete API guide
- [INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md) - Frontend/Android examples
- [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - Production deployment

## 🏗️ Tech Stack

- **Backend**: Python FastAPI
- **Database**: PostgreSQL
- **QR Reading**: pyzbar + OpenCV
- **ORM**: SQLAlchemy
- **Containerization**: Docker

## 🔄 Payment Flow

```
1. Generate QR → 2. Customer pays → 3. Webhook notification
                           ↓
4. Customer uploads slip → 5. Backend verifies → 6. Order completed
```

## 🐛 Troubleshooting

| Problem | Solution |
|---------|----------|
| PostgreSQL error | Run: `docker-compose up -d` |
| Module not found | Activate venv: `source venv/bin/activate` |
| Port 8000 in use | Kill the process using that port |

## 📞 Next Steps

1. Check [QUICK_START.md](QUICK_START.md) for setup
2. Run `bash test_api.sh` to test API
3. Read [INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md) to integrate with your app
4. See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for production deployment

---

**Version**: 1.0.0 | **Ready to go! 🎉**
=======
# slip
​1. การออกแบบสถาปัตยกรรม API สำหรับเว็บไซต์ (API Architecture Design)
​เพื่อให้เว็บไซต์ทำงานร่วมกับระบบที่คุณออกแบบไว้ได้อย่างสมบูรณ์ Backend ของเราควรมี API Endpoints หลักๆ ดังนี้ครับ
​1.1 ลำดับการทำงาน (Workflow)
​Customer -> Website: ลูกค้ากดสั่งซื้อสินค้า เว็บไซต์เรียก API สร้าง QR Code ยอดเงินแบบระบุทศนิยม (เพื่อความแม่นยำในการตรวจสอบ)
​Website -> Customer: แสดง QR Code ให้ลูกค้าสแกนจ่าย
​Android App -> Backend: แอปบนมือถือดักจับ Notification จาก LINE BK แล้วส่ง Webhook มาที่ Backend (บอกว่ามียอดเงิน x.xx บาทเข้ามา)
​Customer -> Website: ลูกค้าอัปโหลดสลิปโอนเงิน (เพื่อความชัวร์และอ้างอิง Ref ID)
​Backend: อ่าน QR บนสลิป ดึงข้อมูล Sending Bank ID และ Transaction Ref ID นำไปเช็คกับฐานข้อมูลว่าตรงกับ Webhook ที่เข้ามาและยอดเงินของ Order หรือไม่
​Website -> Backend: เว็บไซต์ใช้การทำ Polling หรือ WebSocket เพื่อรอรับสถานะว่า "ชำระเงินสำเร็จ"
​1.2 แนะนำเทคโนโลยี (Tech Stack)
​จากข้อมูลที่คุณวิเคราะห์มา ผมแนะนำให้เริ่มต้นด้วย Python (FastAPI) ครับ เนื่องจากพัฒนา API ได้รวดเร็วมาก รองรับ Asynchronous (ดีสำหรับรอ Webhook) และมีไลบรารีจัดการภาพสลิป (pyzbar, opencv) ที่พร้อมใช้งานทันที ส่วนฐานข้อมูลแนะนำเป็น PostgreSQL ครับ
​2. ชุดคำสั่ง (Prompts) สำหรับพัฒนาระบบ
​เพื่อให้การสร้าง API เป็นระบบและโค้ดไม่ตีกัน ผมได้แบ่ง Prompt ออกเป็น 3 ส่วนหลัก คุณสามารถคัดลอก Prompt เหล่านี้ไปสั่งผมทีละส่วนเพื่อเริ่มเขียนโค้ดได้เลยครับ
​Prompt 1: สร้างโครงสร้าง Database และระบบสร้าง QR Code (PromptPay)
​Copy prompt ด้านล่างนี้ไปใช้งาน:
"คุณเป็นผู้เชี่ยวชาญด้าน Python และ FastAPI ช่วยเขียนโค้ดสำหรับระบบรับชำระเงิน PromptPay แบบ Self-hosted โดยเริ่มจาก:
​สร้างโมเดลฐานข้อมูลด้วย SQLAlchemy (PostgreSQL) ประกอบด้วยตาราง orders (id, amount, status, created_at) และ transactions (ref_id, amount, bank_id, status, matched_order_id)
​สร้าง API Endpoint: POST /api/payment/generate-qr โดยรับ order_id และ amount เพื่อสร้าง Payload PromptPay ตามมาตรฐาน EMVCo (รองรับ promptpay-qr) และส่งคืนค่าเป็น string payload เพื่อให้ฝั่งหน้าเว็บนำไปแสดงเป็น QR Code ต่อไป"
​Prompt 2: สร้างระบบรับ Webhook จาก Android Notification
​Copy prompt ด้านล่างนี้ไปใช้งาน:
"เขียนโค้ด FastAPI ต่อจากส่วนที่แล้ว โดยสร้าง Endpoint สำหรับรับ Webhook จากแอปพลิเคชัน Android:
​สร้าง API Endpoint: POST /api/webhook/linebk
​รับ Request JSON ที่ประกอบด้วยข้อมูลเบื้องต้นจากการแจ้งเตือน เช่น {'app': 'LINE', 'title': 'LINE BK', 'text': 'เงินเข้า 100.50 บาท เวลา 12:00', 'timestamp': 1678888888}
​เขียน Logic เบื้องต้นในการใช้ Regex สกัดตัวเลขยอดเงิน (amount) ออกจากข้อความ text
​บันทึกข้อมูลที่ดึงได้ลงตาราง transactions โดยตั้งสถานะเป็น pending_slip"
​Prompt 3: สร้างระบบอัปโหลดสลิป, ถอดรหัส QR (OCR/Pyzbar) และยืนยันยอด
​Copy prompt ด้านล่างนี้ไปใช้งาน:
"เขียนโค้ด FastAPI ต่อจากส่วนที่แล้ว สำหรับจัดการสลิปโอนเงิน:
​สร้าง API Endpoint: POST /api/payment/upload-slip รับไฟล์รูปภาพสลิป (UploadFile)
​ใช้ไลบรารี opencv-python และ pyzbar หรือ promptparse ในการอ่าน QR Code จากรูปภาพสลิป
​ดึงข้อมูล Transaction Ref ID และ Bank ID จาก Payload ของ QR สลิป
​สร้าง Logic ตรวจสอบ: นำ Ref ID ที่ได้ไปเช็คว่าซ้ำซ้อนไหม และจับคู่ยอดเงินให้ตรงกับตาราง orders และข้อมูล Webhook ที่อยู่ใน transactions
​หากตรงกันทั้งหมด ให้อัปเดตสถานะ order เป็น completed และคืนค่า HTTP 200"
​ข้อควรระวังเพิ่มเติมจากความเป็นจริง (Reality Check)
​ความน่าเชื่อถือของ Notification: ระบบปฏิบัติการ Android บางเวอร์ชันอาจหยุดการทำงานของแอปพื้นหลัง ทำให้ Notification Webhook ส่งมาไม่ถึง Backend การออกแบบให้ระบบอ่าน QR จากสลิปเป็นหลัก (ตาม Prompt 3) แล้วค่อยนำไปเช็คกับยอดเงินที่คาดหวัง จึงเป็นวิธีสำรองที่ปลอดภัยที่สุดครับ
​Micro-transactions (ทศนิยม): หากคุณขายของราคาเท่ากันหลายออเดอร์ในเวลาเดียวกัน แนะนำให้ระบบบวกเศษสตางค์แบบสุ่ม (เช่น 100.01 บาท, 100.02 บาท) เพื่อให้จับคู่ Webhook กับ Order ได้ง่ายและแม่นยำขึ้นครับ
