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
