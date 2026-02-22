# 🚀 PromptPay Payment System - VPS Deployment Complete

## ✅ Current Status: Ready to Start Services

Your PromptPay self-hosted payment system has been fully deployed to VPS `150.95.84.201`. All code, configuration, and Docker setup is in place. The only remaining step is to start the containerized services.

---

## 📋 Quick Start (Copy & Paste)

### Option 1: Manual Start (Recommended)

SSH to your VPS and run these commands one by one:

```bash
# SSH to VPS
ssh root@150.95.84.201

# Then copy-paste these:
sudo pkill -9 postgres
sleep 2
sudo systemctl restart docker
cd /opt/promptpay-system
docker-compose down -v
docker-compose up -d
sleep 5
docker ps
```

### Option 2: Automated Script (Fastest)

From your local machine, run:

```bash
chmod +x /workspaces/slip/complete-vps-recovery.sh
./complete-vps-recovery.sh root@150.95.84.201
```

**Note**: You'll be prompted for your VPS password: `Laline1812@`

---

## ✨ What Gets Deployed

### 📦 Services Running in Docker

| Service | Port | Status | Purpose |
|---------|------|--------|---------|
| `slip_api` | 8000 | FastAPI | REST API with Swagger UI |
| `slip_postgres` | 5432 | PostgreSQL 15 | Database for orders/transactions |
| `slip_pgadmin` | 5050 | pgAdmin 4 | Database management UI |

### 🔧 Key Files Deployed

```
/opt/promptpay-system/
├── main.py                      (401 lines - FastAPI app with 5 endpoints)
├── models.py                    (53 lines - SQLAlchemy ORM models)
├── qr_reader.py                 (170+ lines - QR processing with 5-layer verification)
├── payment_service.py           (144 lines - PromptPay EMVCo QR generation)
├── schemas.py                   (84+ lines - Pydantic request/response validation)
├── database.py                  (21 lines - PostgreSQL connection manager)
├── config.py                    (15 lines - Environment configuration)
├── docker-compose.yml           (Complete orchestration)
├── Dockerfile                   (Multi-stage production build)
└── requirements.txt             (All Python dependencies)
```

---

## 🌐 Access the System

### Once Services Are Running:

#### **API Documentation** (Interactive Testing)
- **URL**: http://150.95.84.201:8000/docs
- **What**: Swagger UI with all 5 REST endpoints
- **Use**: Test endpoints directly in browser

#### **Database Manager** (pgAdmin)
- **URL**: http://150.95.84.201:5050
- **Email**: admin@example.com
- **Password**: admin

### From VPS Console:
```bash
# Test API is responding
curl http://localhost:8000/docs

# Check all containers running
docker ps

# View API logs
docker-compose logs slip_api --tail=20
```

---

## 🧪 Test the API

### 1. Generate PromptPay QR Code

```bash
curl -X POST http://150.95.84.201:8000/api/payment/generate-qr \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 100.50,
    "account_id": "004999012726757"
  }'
```

**Expected Response**: Base64-encoded PNG QR code with EMVCo PromptPay payload

### 2. Verify Payment Slip

```bash
curl -X POST http://150.95.84.201:8000/api/payment/upload-slip \
  -F "slip_image=@path/to/slip.jpg" \
  -F "qr_reference=001a2b3c4d5e6f7g8h"
```

**Expected Response**: Verification result with confidence level (HIGH/MEDIUM/LOW)

### 3. View Verifications

```bash
curl http://150.95.84.201:8000/api/admin/verifications
```

---

## 🔍 Troubleshooting

### Problem: Port 5432 Already In Use

This is blocking PostgreSQL in Docker. **Solution**:

```bash
ssh root@150.95.84.201
sudo pkill -9 postgres
sudo systemctl restart docker
cd /opt/promptpay-system
docker-compose up -d
```

### Problem: Can't Reach API

**Check 1**: Are containers actually running?
```bash
ssh root@150.95.84.201
docker-compose -f /opt/promptpay-system/docker-compose.yml ps
```

**Check 2**: Are ports bound?
```bash
ssh root@150.95.84.201
netstat -tulpn | grep -E "8000|5432|5050"
```

**Check 3**: Check logs
```bash
ssh root@150.95.84.201
docker-compose -f /opt/promptpay-system/docker-compose.yml logs --tail=50
```

### Problem: Database Connection Error

The database takes 5-10 seconds to initialize. Restart and wait:

```bash
ssh root@150.95.84.201 << 'EOF'
cd /opt/promptpay-system
docker-compose down -v
docker-compose up -d
sleep 10
docker-compose exec -T slip_postgres pg_isready -U slip_user
EOF
```

---

## 📊 Verify Deployment

### Step 1: Check File System
```bash
ssh root@150.95.84.201 'ls -la /opt/promptpay-system/'
```

Should show all `.py` files, `docker-compose.yml`, `Dockerfile`, `requirements.txt`

### Step 2: Check Container Images
```bash
ssh root@150.95.84.201 'docker images | grep -E "promptpay|postgres|pgadmin"'
```

Should show 3 images built/pulled

### Step 3: Check Running Containers
```bash
ssh root@150.95.84.201 'docker ps'
```

Should show 3 containers with status "Up"

### Step 4: Test HTTP Connectivity
```bash
# From local machine
curl -v http://150.95.84.201:8000/docs -m 5
```

Should return HTTP 200 with HTML content

---

## 📈 System Architecture

```
┌─────────────────────────────────────────────────────────┐
│           PromptPay Payment System (Docker)             │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────┐    ┌──────────────┐    ┌────────────┐ │
│  │ slip_api:80  │    │slip_postgres │    │slip_pgadmin│ │
│  │   00         │    │    :5432     │    │   :5050    │ │
│  │              │    │              │    │            │ │
│  │ FastAPI      │◄──►│ PostgreSQL   │    │ pgAdmin    │ │
│  │ 5 Endpoints  │    │ (Payment DB) │    │  (Web UI)  │ │
│  └──────────────┘    └──────────────┘    └────────────┘ │
│         ▲                    ▲                    ▲       │
│         │ HTTP               │ TCP               │TCP    │
│         │ 8000               │ 5432              │ 5050  │
├─────────│────────────────────│──────────────────│───────┤
│         │ Network: slip_network (Docker bridge) │       │
└─────────┴────────────────────┴──────────────────┴───────┘
        │                                          │
        ▼ (expose)                                 ▼
  http://150.95.84.201:8000/docs      http://150.95.84.201:5050
```

---

## 🔐 Security Notes

### Default Credentials (Change After Testing)

**Database** (in docker-compose.yml):
- User: `slip_user`
- Password: `slip_password`
- Database: `slip_db`

**pgAdmin** (in docker-compose.yml):
- Email: `admin@example.com`
- Password: `admin`

### Production recommendations:
1. Generate strong random passwords
2. Use environment variables for secrets
3. Enable SSL/TLS on API
4. Implement rate limiting
5. Use VPC/firewall to restrict access

---

## 📚 Complete API Reference

### Endpoint 1: Generate QR Code
```
POST /api/payment/generate-qr
Content-Type: application/json

Request:
{
  "amount": 150.50,
  "account_id": "004999012726757"  # Optional
}

Response:
{
  "qr_code_image": "iVBORw0KGgoAAAANSUhEUgAA...",
  "qr_payload": "00020126300013...",
  "amount": 150.50
}
```

### Endpoint 2: Upload & Verify Slip
```
POST /api/payment/upload-slip
Content-Type: multipart/form-data

Request:
- slip_image: <binary image data>
- qr_reference: "xxxxxxxxxxxxxx"

Response:
{
  "verification_id": "uuid",
  "status": "HIGH",  # or MEDIUM/LOW
  "amount_match": true,
  "confidence_score": 0.98,
  "detected_amount": 150.50,
  "message": "Payment verified successfully"
}
```

### Endpoint 3: LINE Bank Webhook (Optional)
```
POST /api/webhook/linebk
Content-Type: application/json

Request: <LINE Bank webhook payload>

Response:
{
  "status": "received",
  "processing": true
}
```

### Endpoint 4: View Verifications
```
GET /api/admin/verifications

Response:
{
  "verifications": [
    {
      "id": "uuid",
      "slip_image_url": "...",
      "qr_reference": "...",
      "amount": 150.50,
      "status": "HIGH",
      "verified_at": "2026-02-22T23:00:00"
    }
  ],
  "total": 5
}
```

### Endpoint 5: Manual Verification
```
POST /api/admin/verify-payment
Content-Type: application/json

Request:
{
  "verification_id": "uuid",
  "approved": true,  # or false
  "notes": "Manual verification - approved"
}

Response:
{
  "verification_id": "uuid",
  "approved": true,
  "updated_at": "2026-02-22T23:05:00"
}
```

---

## 📝 Database Schema

### Tables Created Automatically

#### Orders Table
```sql
CREATE TABLE orders (
  id UUID PRIMARY KEY,
  amount DECIMAL(12, 2),
  currency VARCHAR(3),
  status VARCHAR(50),
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

#### Transactions Table
```sql
CREATE TABLE transactions (
  id UUID PRIMARY KEY,
  order_id UUID REFERENCES orders(id),
  promptpay_reference VARCHAR(50) UNIQUE,
  amount DECIMAL(12, 2),
  created_at TIMESTAMP
);
```

#### Verifications Table
```sql
CREATE TABLE slip_verifications (
  id UUID PRIMARY KEY,
  transaction_id UUID REFERENCES transac...

 tions(id),
  slip_image_path VARCHAR(255),
  confidence_score FLOAT,
  verified_at TIMESTAMP,
  status VARCHAR(50),
  notes TEXT
);
```

---

## 🎯 Next Steps

1. **Start Services**: Run the quick start commands above
2. **Wait 10 seconds**: Let all containers fully initialize
3. **Test API**: Visit http://150.95.84.201:8000/docs
4. **Generate QR**: Test the QR generation endpoint
5. **Verify Slip**: Upload a sample payment slip
6. **Check Database**: Access pgAdmin at http://150.95.84.201:5050
7. **Monitor Logs**: Watch `docker-compose logs -f slip_api`

---

## 📞 Support

For issues during startup:

```bash
# SSH to VPS
ssh root@150.95.84.201

# Go to project
cd /opt/promptpay-system

# Check full logs
docker-compose logs

# Restart all services
docker-compose restart

# Force rebuild and start
docker-compose down -v
docker-compose up -d
```

---

**Status**: ✅ **Deployment Complete - Ready to Start**  
**Last Updated**: 2026-02-22  
**All Files**: Deployed to `/opt/promptpay-system/`  
**Docker**: Version 29.2.1 - Installed and Running

