# 🚀 Deploy to VPS - Step-by-Step Guide

## VPS Details
- **Host**: 150.95.84.201
- **User**: root
- **Port**: 22 (default SSH)

---

## Step 1: Upload Project Files to VPS

### Option A: Using SCP (Recommended)
```bash
# From your local machine, in the project directory:
scp -r /path/to/project/* root@150.95.84.201:/opt/promptpay-system/

# Or use the helper script:
bash upload_to_vps.sh
```

### Option B: Using SFTP
```bash
sftp root@150.95.84.201
mkdir /opt/promptpay-system
cd /opt/promptpay-system
put -r *
```

### Option C: Git Clone (If you have a Git repo)
```bash
ssh root@150.95.84.201
cd /opt/
git clone <your-repo-url> promptpay-system
cd promptpay-system
```

---

## Step 2: SSH into VPS

```bash
ssh root@150.95.84.201
# Password: Laline1812@
```

---

## Step 3: Navigate to Project Directory

```bash
cd /opt/promptpay-system
ls -la
```

You should see:
```
docker-compose.yml
Dockerfile
main.py
models.py
qr_reader.py
payment_service.py
schemas.py
config.py
database.py
requirements.txt
...
```

---

## Step 4: Run Deployment Script

```bash
chmod +x DEPLOY_TO_VPS.sh
./DEPLOY_TO_VPS.sh
```

This script will:
- ✅ Install Docker and Docker Compose
- ✅ Start Docker service
- ✅ Create environment file (.env)
- ✅ Deploy containers with docker-compose
- ✅ Verify all services are running

---

## Step 5: Verify Deployment

```bash
# Check running containers
docker-compose ps

# Check logs
docker-compose logs -f

# View database
docker-compose exec db psql -U paymentuser -d payment_db
```

---

## Step 6: Access Your System

Once deployed, access at:

| Service | URL |
|---------|-----|
| **API** | http://150.95.84.201:8000 |
| **Swagger Docs** | http://150.95.84.201:8000/docs |
| **ReDoc** | http://150.95.84.201:8000/redoc |
| **pgAdmin** | http://150.95.84.201:5050 |

### Default Credentials:
- pgAdmin: admin@admin.com / admin
- Database: paymentuser / PaymentSecure2024

---

## Step 7: Post-Deployment Setup

### 1. Change Database Password
```bash
# Connect to database
docker-compose exec db psql -U postgres

# Inside psql:
ALTER USER paymentuser WITH PASSWORD 'NewSecurePassword123!';
\q

# Update .env file
nano .env
# Change: DB_PASSWORD=NewSecurePassword123!

# Restart services
docker-compose down
docker-compose up -d
```

### 2. Set Up SSL Certificate (HTTPS)
```bash
# Install Certbot
apt-get install -y certbot python3-certbot-nginx

# Get certificate (replace example.com with your domain)
certbot certonly --standalone -d example.com

# Update docker-compose to use SSL
nano docker-compose.yml
# Add volume for certificates and update ports to 443
```

### 3. Configure Firewall
```bash
# Allow only necessary ports
ufw allow 22/tcp   # SSH
ufw allow 80/tcp   # HTTP
ufw allow 443/tcp  # HTTPS
ufw allow 5050/tcp # pgAdmin (restrict to your IP)
ufw enable
```

### 4. Set Up Monitoring/Alerts
```bash
# Monitor logs in real-time
docker-compose logs -f api

# Or check specific service
docker-compose logs -f db
```

---

## Step 8: Test the System

### Generate a Test QR Code
```bash
curl -X POST http://150.95.84.201:8000/api/payment/generate-qr \
  -H "Content-Type: application/json" \
  -d '{
    "account_id": "004999012726757",
    "amount": 1500.50
  }'
```

### Expected Response
```json
{
  "status": "success",
  "qr_code_image": "data:image/png;base64,iVBORw0KGgo...",
  "amount": 1500.50,
  "reference": "..."
}
```

---

## Troubleshooting

### Docker not starting
```bash
systemctl status docker
systemctl start docker
```

### Port already in use
```bash
# Check what's using port 8000
lsof -i :8000

# Kill the process
kill -9 <PID>
```

### Database connection error
```bash
# Check database logs
docker-compose logs db

# Verify database is running
docker-compose ps db
```

### Can't upload files
```bash
# Check .env file permissions
chmod 644 .env

# Check docker-compose access
docker-compose up -d
```

---

## Monitoring & Maintenance

### View All Logs
```bash
docker-compose logs -f
```

### Check System Resources
```bash
docker stats

# Or use top command
docker-compose exec api top
```

### Backup Database
```bash
docker-compose exec db pg_dump -U paymentuser payment_db > backup.sql
```

### Restore Database
```bash
docker-compose exec -T db psql -U paymentuser payment_db < backup.sql
```

---

## Security Checklist

After deployment, please complete:

- [ ] Change root VPS password
- [ ] Change database password
- [ ] Change SECRET_KEY in .env
- [ ] Set up SSH key authentication (disable password)
- [ ] Enable firewall
- [ ] Set up SSL certificate
- [ ] Configure backup strategy
- [ ] Set up monitoring/alerts
- [ ] Disable root SSH login
- [ ] Enable automatic updates

---

## Quick Commands Reference

```bash
# SSH into VPS
ssh root@150.95.84.201

# Navigate to project
cd /opt/promptpay-system

# View running services
docker-compose ps

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Start services
docker-compose up -d

# Restart services
docker-compose restart

# Update and redeploy
docker-compose down
docker-compose up -d --build

# Remove everything (careful!)
docker-compose down -v
```

---

## Support

If you need help:

1. Check the logs: `docker-compose logs -f`
2. Review DEPLOYMENT_GUIDE.md in the project
3. Check Docker documentation: https://docs.docker.com
4. Check FastAPI documentation: https://fastapi.tiangolo.com

---

## System Status After Deployment

Once successfully deployed, you should have:

✅ API running on port 8000
✅ PostgreSQL database on port 5432
✅ pgAdmin running on port 5050
✅ All microservices connected
✅ Automatic health checks enabled
✅ Persistent data volumes configured
✅ Complete audit trail system ready
✅ 5-layer verification system active

🎉 **Your PromptPay payment system is live!**
