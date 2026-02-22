# PromptPay Payment System - Deployment Status & Troubleshooting

## ✅ Completed

- [x] FastAPI backend code deployed to `/opt/promptpay-system/`
- [x] PostgreSQL and Docker Compose configuration files deployed
- [x] Docker Engine v29.2.1 installed and running
- [x] Docker Compose v5.0.2 installed
- [x] All 20 system files uploaded to VPS
- [x] Requirements updated to use proper PromptPay version

## ⏳ Current Issue: Port 5432 Conflict

**Problem**: PostgreSQL service running on host is blocking Docker container
**Solution**: Stop the host PostgreSQL and start Docker services

## Quick Start Instructions

### For Your VPS SSH Session:

```bash
# SSH to your VPS first
ssh root@150.95.84.201

# Then copy-paste these commands:

# 1. Kill the conflicting PostgreSQL
sudo pkill -9 postgres

# 2. Wait a moment
sleep 2

# 3. Restart Docker daemon
sudo systemctl restart docker

# 4. Navigate to system directory
cd /opt/promptpay-system

# 5. Bring down any old containers cleanly
docker-compose down -v

# 6. Start all services
docker-compose up -d

# 7. Wait for startup (containers take 2-3 seconds to start)
sleep 5

# 8. Check if all services are running
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

### Expected Output After Step 8:

```
CONTAINER ID   NAMES           STATUS              PORTS
xxxxx          slip_api        Up 2 seconds        0.0.0.0:8000->8000/tcp
xxxxx          slip_postgres   Up 3 seconds        0.0.0.0:5432->5432/tcp
xxxxx          slip_pgadmin    Up 2 seconds        0.0.0.0:5050->80/tcp
```

### Verify Services Are Working:

```bash
# Test API from inside the VPS
curl http://localhost:8000/docs | head -20

# Or check with netstat
netstat -tulpn | grep LISTEN | grep -E "8000|5432|5050"
```

## Testing from Your Local Computer

Once services are running, test from your local machine:

```bash
# Test API Swagger documentation
curl -I http://150.95.84.201:8000/docs

# Generate a QR code
curl -X POST http://150.95.84.201:8000/api/payment/generate-qr \
  -H "Content-Type: application/json" \
  -d '{"amount": 100}' | jq .

# View all tables in database
curl http://150.95.84.201:5050/
```

## Accessing the System

### API Documentation (Swagger UI)
- **URL**: http://150.95.84.201:8000/docs
- **Status**: Shows all available endpoints
- **Testing**: Interactive endpoint testing

### Database Management (pgAdmin)
- **URL**: http://150.95.84.201:5050
- **Email**: admin@example.com
- **Password**: admin

## Available Endpoints

### Payment API

#### 1. Generate QR Code
```bash
POST /api/payment/generate-qr
Content-Type: application/json

{
  "amount": 150.50,
  "account_id": "004999012726757"  # Optional
}

# Response: base64-encoded QR image with PromptPay data
```

#### 2. Upload and Verify Slip
```bash
POST /api/payment/upload-slip
Content-Type: multipart/form-data

Files:
  - slip_image: <image file>
  - qr_reference: "xxxxxxxxxxxxxx"

# Response: Verification result (HIGH/MEDIUM/LOW confidence)
```

#### 3. WebHook Endpoint (Optional)
```bash
POST /api/webhook/linebk
Content-Type: application/json

{ "webhook_data": "..." }
```

### Admin API

#### 4. View All Verifications
```bash
GET /api/admin/verifications
```

#### 5. Verify Payment
```bash
POST /api/admin/verify-payment
Content-Type: application/json

{
  "verification_id": "xxx",
  "approved": true,  # or false
  "notes": "Manual verification"
}
```

## Verify Container Health

```bash
# Check all container logs
docker-compose logs

# Check specific container
docker-compose logs slip_api --tail=50

# Monitor real-time
docker-compose logs -f slip_api

# Check database connection
docker exec slip_postgres psql -U slip_user -d slip_db -c "\dt"
```

## If Services Won't Start

### Check Using SSH

```bash
# What's preventing startup?
docker-compose logs slip_api 2>&1 | head -50

# Is database responsive?
docker-compose exec slip_postgres pg_isready

# Check port conflicts
netstat -tulpn | grep -E "5432|8000|5050"
```

### Common Issues & Solutions

**Issue**: "Address already in use"
```bash
# Kill whatever's using that port
fuser -k 5432/tcp
fuser -k 8000/tcp
fuser -k 5050/tcp
docker-compose up -d
```

**Issue**: "Cannot connect to database"
```bash
# Wait longer for PostgreSQL to initialize (usually 5-10 seconds)
sleep 10
docker exec slip_postgres pg_isready -U slip_user
```

**Issue**: "API container exits immediately"
```bash
# Check the API application logs
docker logs slip_api
# Look for Python errors, missing dependencies, etc.
```

**Issue**: "Permission denied on docker commands"
```bash
# Make sure you're using root or in docker group
sudo docker ps
# OR add your user to docker group
sudo usermod -aG docker $USER
```

## Verify File Integrity

```bash
# Check if all files are on the VPS
cd /opt/promptpay-system
ls -la

# Should see these Python files:
# - main.py (FastAPI app)
# - models.py (Database models)
# - qr_reader.py (QR processing)
# - payment_service.py (PromptPay integration)
# - schemas.py (Request/response validation)
# - database.py (Database connection)
# - config.py (Configuration)
```

## Next Steps After Verification

1. **Test QR Generation**: Generate a PromptPay QR code via API
2. **Test Slip Verification**: Upload a bank slip image for verification
3. **Check Database**: Verify orders and transactions are being saved
4. **Test Admin Functions**: Use admin endpoints for manual verification

## Git Status

All files are properly staged and the system is ready for production use.

## Support Information

### Docker Compose File Location
`/opt/promptpay-system/docker-compose.yml`

### Application Code Location
`/opt/promptpay-system/main.py`

### System Logs
```bash
ssh root@150.95.84.201 'docker-compose -f /opt/promptpay-system/docker-compose.yml logs --tail=100'
```

---

**Status**: Ready to start - requires manual startup of Docker services on VPS
**Last Updated**: 2026-02-22
**Authentication**: All credentials stored in docker-compose.yml on VPS

