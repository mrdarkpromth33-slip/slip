# 🚀 PRODUCTION DEPLOYMENT GUIDE

> **⚠️ READ THIS BEFORE GOING LIVE**

This guide ensures your PromptPay Payment System is production-ready and secure.

---

## 📋 Pre-Production Checklist

### 🔐 Security

- [ ] Change all default passwords
- [ ] Generate strong SSL/TLS certificates
- [ ] Configure firewall rules
- [ ] Disable DEBUG mode
- [ ] Set secure API keys
- [ ] Configure CORS properly
- [ ] Enable rate limiting
- [ ] Set up monitoring alerts

### 📊 Database

- [ ] Enable automatic backups
- [ ] Configure backup retention (30+ days)
- [ ] Test backup restoration
- [ ] Set up replication (if applicable)
- [ ] Configure connection pooling
- [ ] Enable query logging
- [ ] Set up performance monitoring

### 🌐 Infrastructure

- [ ] Set up load balancer
- [ ] Configure HTTPS/SSL
- [ ] Set up CDN for static files
- [ ] Configure reverse proxy (Nginx)
- [ ] Enable gzip compression
- [ ] Set up DDoS protection
- [ ] Configure health checks

### 📈 Monitoring & Logging

- [ ] Set up centralized logging (ELK Stack)
- [ ] Configure application monitoring
- [ ] Set up error tracking (Sentry)
- [ ] Create monitoring dashboard
- [ ] Configure alerting rules
- [ ] Implement log retention policies
- [ ] Test log rotation

### 🔄 Deployment

- [ ] Set up CI/CD pipeline
- [ ] Automate dependency updates
- [ ] Create deployment runbooks
- [ ] Plan rollback procedures
- [ ] Test zero-downtime deployments
- [ ] Document deployment process
- [ ] Prepare disaster recovery plan

---

## 🔒 Step 1: Security Hardening

### 1.1 Change All Credentials

**File**: `docker-compose.yml`
```yaml
postgres:
  environment:
    POSTGRES_USER: your_prod_db_user        # ✏️ Change from "slip_user"
    POSTGRES_PASSWORD: GeneratedSecurePass123!  # ✏️ 20+ chars, mixed case

pgadmin:
  environment:
    PGADMIN_DEFAULT_EMAIL: ops@your-domain.com  # ✏️ Your email
    PGADMIN_DEFAULT_PASSWORD: YourSecurePass456!! # ✏️ Change
```

### 1.2 Create .env File

**File**: `.env`
```bash
# Database
DATABASE_URL=postgresql://your_prod_db_user:GeneratedSecurePass123!@postgres:5432/slip_db

# API Security
API_ENV=production
DEBUG=false
SECRET_KEY=your-random-256-character-secret-key-here
API_KEY=your-api-key-for-external-calls

# TLS/SSL
SSL_CERT_PATH=/etc/ssl/certs/your-domain.crt
SSL_KEY_PATH=/etc/ssl/private/your-domain.key

# Rate Limiting
RATE_LIMIT_REQUESTS=100
RATE_LIMIT_PERIOD=3600  # 1 hour

# Logging
LOG_LEVEL=INFO
LOG_FILE=/var/log/slip-api.log

# Email Notifications
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=notifications@your-domain.com
SMTP_PASSWORD=your-app-password
SMTP_FROM=payments@your-domain.com

# Business Rules
MERCHANT_ID=004999012726757
MERCHANT_NAME=Your Business Name
CURRENCY=THB
CONTACT_EMAIL=support@your-domain.com
```

### 1.3 Update main.py for Production

```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from pydantic_settings import BaseSettings
import os

class Settings(BaseSettings):
    database_url: str
    debug: bool = False
    secret_key: str
    api_key: str
    
    class Config:
        env_file = ".env"

settings = Settings()

app = FastAPI(
    title="PromptPay Payment System",
    version="1.0.0",
    docs_url="/api/docs" if not settings.debug else "/docs",
    redoc_url="/api/redoc" if not settings.debug else "/redoc",
    openapi_url="/api/openapi.json" if not settings.debug else "/openapi.json"
)

# Trust only your load balancer
app.add_middleware(
    TrustedHostMiddleware,
    allowed_hosts=["your-domain.com", "api.your-domain.com"]
)

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://your-domain.com"],  # ✏️ HTTPS only
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT"],  # Not "*"
    allow_headers=["Content-Type", "Authorization"],  # Not "*"
    max_age=3600
)

# Rate limiting
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter

@app.get("/health")
async def health_check():
    return {"status": "healthy", "environment": "production"}
```

---

## 📊 Step 2: Database Configuration

### 2.1 Backup Strategy

**Create**: `backup.sh`
```bash
#!/bin/bash

BACKUP_DIR="/opt/backups/promptpay"
DATE=$(date +%Y%m%d_%H%M%S)
APP_ENV=production

mkdir -p "$BACKUP_DIR"

# Full database backup
docker exec slip_postgres pg_dump \
  -U ${DB_USER} \
  -d slip_db \
  --format=custom \
  --verbose \
  > "$BACKUP_DIR/backup_$DATE.dump"

echo "✅ Backup created: $BACKUP_DIR/backup_$DATE.dump"

# Upload to S3
aws s3 cp "$BACKUP_DIR/backup_$DATE.dump" \
  s3://your-bucket/backups/production/ \
  --storage-class GLACIER

# Keep only 30 days locally
find "$BACKUP_DIR" -name "backup_*.dump" -mtime +30 -delete

echo "✅ Old backups deleted"
```

### 2.2 Automated Backup Cron

```bash
# Add to crontab -e
# Daily backup at 2 AM
0 2 * * * /opt/backup.sh >> /var/log/backup.log 2>&1

# Weekly full backup at Sunday 3 AM
0 3 * * 0 /opt/backup-full.sh >> /var/log/backup-full.log 2>&1
```

### 2.3 Connection Pooling

**Update**: `database.py`
```python
from sqlalchemy import create_engine
from sqlalchemy.pool import QueuePool

engine = create_engine(
    DATABASE_URL,
    poolclass=QueuePool,
    pool_size=20,           # Number of connections to keep
    max_overflow=40,        # Additional connections when needed
    pool_pre_ping=True,     # Verify connections before using
    pool_recycle=3600,      # Recycle connections after 1 hour
    echo=False if not DEBUG else True
)
```

---

## 🌐 Step 3: HTTPS/SSL Setup

### 3.1 Get SSL Certificate

```bash
# Using Let's Encrypt (Free)
sudo certbot certonly --standalone \
  -d api.your-domain.com \
  -d your-domain.com

# Certificates will be at:
# /etc/letsencrypt/live/your-domain.com/fullchain.pem
# /etc/letsencrypt/live/your-domain.com/privkey.pem
```

### 3.2 Nginx Configuration

**Create**: `nginx.conf`
```nginx
upstream api {
    server slip_api:8000;
}

server {
    listen 80;
    server_name api.your-domain.com;
    
    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.your-domain.com;
    
    # SSL certificates
    ssl_certificate /etc/ssl/certs/fullchain.pem;
    ssl_certificate_key /etc/ssl/private/privkey.pem;
    
    # SSL security
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "DENY" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # Gzip compression
    gzip on;
    gzip_types text/plain text/css application/json;
    
    location / {
        proxy_pass http://api;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 30s;
    }
}
```

---

## 📈 Step 4: Monitoring & Logging

### 4.1 Application Monitoring

```python
# Add to main.py
from prometheus_client import Counter, Histogram, generate_latest

# Metrics
request_count = Counter(
    'api_requests_total',
    'Total API requests',
    ['method', 'endpoint', 'status']
)

request_duration = Histogram(
    'api_request_duration_seconds',
    'Request duration',
    ['method', 'endpoint']
)

@app.middleware("http")
async def add_metrics(request, call_next):
    start = time.time()
    response = await call_next(request)
    duration = time.time() - start
    
    request_count.labels(
        method=request.method,
        endpoint=request.url.path,
        status=response.status_code
    ).inc()
    
    request_duration.labels(
        method=request.method,
        endpoint=request.url.path
    ).observe(duration)
    
    return response

@app.get("/metrics")
async def metrics():
    return generate_latest()
```

### 4.2 Logging Configuration

```python
import logging
from logging.handlers import RotatingFileHandler

# Create logs directory
os.makedirs("/var/log/promptpay", exist_ok=True)

# Configure logger
logger = logging.getLogger(__name__)
handler = RotatingFileHandler(
    "/var/log/promptpay/api.log",
    maxBytes=10485760,  # 10MB
    backupCount=20
)

formatter = logging.Formatter(
    '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
handler.setFormatter(formatter)
logger.addHandler(handler)
logger.setLevel(logging.INFO)
```

---

## 🐳 Step 5: Docker Production Setup

### 5.1 docker-compose.prod.yml

```yaml
version: '3.8'

services:
  postgres:
    restart: always
    environment:
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./backups:/backups

  api:
    restart: always
    build: .
    environment:
      DATABASE_URL: postgresql://${DB_USER}:${DB_PASSWORD}@postgres:5432/slip_db
      DEBUG: "false"
      LOG_LEVEL: "INFO"
    depends_on:
      postgres:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s

  nginx:
    image: nginx:latest
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - /etc/letsencrypt:/etc/ssl:ro
    depends_on:
      - api

volumes:
  postgres_data:
    driver: local
```

### 5.2 Start Production

```bash
# Build and start
docker-compose -f docker-compose.yml \
  -f docker-compose.prod.yml \
  up -d

# Verify
docker-compose ps
docker-compose logs --tail=50

# Monitor
docker stats
```

---

## 🔄 Step 6: CI/CD Pipeline

### 6.1 GitHub Actions

**Create**: `.github/workflows/deploy.yml`
```yaml
name: Deploy to Production

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15-alpine
        env:
          POSTGRES_PASSWORD: test
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      - run: pip install -r requirements.txt
      - run: pytest

  deploy:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy to VPS
        env:
          SSH_PRIVATE_KEY: ${{ secrets.SSH_PRIVATE_KEY }}
          VPS_HOST: ${{ secrets.VPS_HOST }}
          VPS_USER: ${{ secrets.VPS_USER }}
        run: |
          mkdir -p ~/.ssh
          echo "$SSH_PRIVATE_KEY" > ~/.ssh/id_rsa
          chmod 600 ~/.ssh/id_rsa
          ssh-keyscan $VPS_HOST >> ~/.ssh/known_hosts
          
          ssh $VPS_USER@$VPS_HOST << 'EOF'
          cd /opt/promptpay-system
          git pull origin main
          docker-compose up -d
          EOF
```

---

## 🚨 Step 7: Monitoring & Alerts

### 7.1 Health Checks

```bash
# Monitor every minute
*/1 * * * * curl -f http://api.your-domain.com/health || \
  send_alert "API is down"

# Monitor database
0 * * * * docker exec slip_postgres pg_isready -U prod_user || \
  send_alert "Database is down"
```

### 7.2 Error Tracking (Sentry)

```python
import sentry_sdk

sentry_sdk.init(
    dsn="https://your-sentry-dsn@sentry.io/project-id",
    environment="production",
    traces_sample_rate=0.1
)

@app.exception_handler(Exception)
async def exception_handler(request, exc):
    sentry_sdk.capture_exception(exc)
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error"}
    )
```

---

## 🔄 Step 8: Disaster Recovery

### 8.1 Backup Verification

```bash
# Weekly backup restore test
0 4 * * 0 /opt/test-restore-backup.sh

# Script content:
#!/bin/bash
BACKUP=/opt/backups/latest.dump
docker exec slip_postgres pg_restore \
  -U ${DB_USER} \
  -d slip_db_test \
  --verbose \
  $BACKUP && echo "✅ Backup verified" || echo "❌ Backup failed"
```

### 8.2 Load Testing

```bash
# Using Apache Bench
ab -n 10000 -c 100 https://api.your-domain.com/health

# Using k6
k6 run --vus 100 --duration 30s load-test.js
```

---

## 📋 Pre-Launch Checklist

```bash
# 1. Security
[ ] All passwords changed
[ ] HTTPS configured
[ ] Firewall rules applied
[ ] DEBUG=false

# 2. Database
[ ] Backups working
[ ] Connection pooling enabled
[ ] Replication configured

# 3. Monitoring
[ ] Logging configured
[ ] Metrics enabled
[ ] Alerts set up
[ ] Error tracking working

# 4. Performance
[ ] Load test passed
[ ] Caching configured
[ ] CDN set up
[ ] Compression enabled

# 5. Operational
[ ] Runbooks written
[ ] On-call process defined
[ ] Disaster recovery tested
[ ] Team trained
```

---

## 🚀 Deployment Steps

```bash
# 1. Prepare
git pull origin main
cp .env.example .env
# ✏️ Edit .env with production values

# 2. Build
docker-compose build --no-cache

# 3. Start
docker-compose -f docker-compose.yml \
  -f docker-compose.prod.yml \
  up -d

# 4. Verify
docker-compose ps
docker-compose logs --tail=100

# 5. Monitor
docker stats
curl https://api.your-domain.com/health

# 6. Test
curl -X POST https://api.your-domain.com/api/payment/generate-qr \
  -H "Content-Type: application/json" \
  -d '{"amount": 100}'
```

---

## 📞 Support & Escalation

**If something goes wrong:**

1. **Check logs**: `docker-compose logs --tail=100`
2. **Restart service**: `docker-compose restart slip_api`
3. **Full restart**: `docker-compose down && docker-compose up -d`
4. **Database recovery**: Run backup restoration script
5. **Rollback**: `git revert <commit>` and redeploy

---

## 📚 Additional Resources

- [Docker Production Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [PostgreSQL Backup & Recovery](https://www.postgresql.org/docs/current/backup.html)
- [FastAPI Security](https://fastapi.tiangolo.com/advanced/security/)
- [Nginx Security](https://nginx.org/en/docs/)

---

**🎉 You're ready for production!**

Make sure to:
1. ✅ Read this entire guide
2. ✅ Complete the checklist
3. ✅ Test all procedures
4. ✅ Document your setup
5. ✅ Train your team

Good luck! 🚀

