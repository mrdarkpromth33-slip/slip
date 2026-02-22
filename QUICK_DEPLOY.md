# Deploy to VPS - Complete Instructions

## Your VPS Details
```
Host:     150.95.84.201
User:     root
Password: Laline1812@
```

---

## 🚀 Quick 3-Step Deployment

### Step 1: Upload Files to VPS (From Your Local Machine)

```bash
cd /workspaces/slip
chmod +x upload_to_vps.sh
./upload_to_vps.sh
```

This uploads all project files to `/opt/promptpay-system` on your VPS.

---

### Step 2: Deploy on VPS (SSH into VPS)

```bash
# Connect to VPS
ssh root@150.95.84.201
# Password: Laline1812@

# Navigate to project directory
cd /opt/promptpay-system

# Run the deployment script
chmod +x DEPLOY_TO_VPS.sh
./DEPLOY_TO_VPS.sh
```

The deployment script will:
- ✅ Install Docker and Docker Compose
- ✅ Create environment configuration
- ✅ Build Docker containers
- ✅ Start PostgreSQL database
- ✅ Start FastAPI server
- ✅ Verify all services

**Wait for the script to complete** (takes 3-5 minutes on first run)

---

### Step 3: Verify Deployment

```bash
# Check running services
docker-compose ps

# View logs
docker-compose logs -f

# Check API health
curl http://localhost:8000/docs
```

---

## 🌐 Access Your System

Once deployed, access at:

| Service | URL |
|---------|-----|
| **Swagger API Docs** | http://150.95.84.201:8000/docs |
| **ReDoc Documentation** | http://150.95.84.201:8000/redoc |
| **REST API** | http://150.95.84.201:8000 |
| **pgAdmin (Database)** | http://150.95.84.201:5050 |

### Database Credentials (in pgAdmin)
- **Username**: paymentuser
- **Password**: PaymentSecure2024
- **Database**: payment_db

### pgAdmin Web UI
- **Email**: admin@admin.com
- **Password**: admin

---

## 📝 Test the System

### Generate a QR Code
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
  "reference": "REF-12345"
}
```

---

## 🔒 Post-Deployment Security Setup

### ⚠️ CRITICAL: Change Passwords Immediately

```bash
# SSH to VPS
ssh root@150.95.84.201

# 1. Change database password
cd /opt/promptpay-system
nano .env
# Change: DB_PASSWORD=NewSecurePassword123!

# 2. Update PostgreSQL password
docker-compose exec db psql -U postgres

# Inside psql:
ALTER USER paymentuser WITH PASSWORD 'NewSecurePassword123!';
\q

# 3. Restart services with new password
docker-compose down
docker-compose up -d

# 4. Change root VPS password
passwd
```

### Enable HTTPS (SSL Certificate)

```bash
# Install certbot
apt-get install -y certbot python3-certbot-standalone

# Get certificate (replace example.com with your domain)
certbot certonly --standalone -d example.com

# Update docker-compose.yml to use SSL
nano docker-compose.yml
# Add HTTPS port 443 and certificate volumes
```

### Configure Firewall

```bash
# Allow SSH
ufw allow 22/tcp

# Allow HTTP
ufw allow 80/tcp

# Allow HTTPS
ufw allow 443/tcp

# Restrict pgAdmin to specific IP (optional)
ufw allow from 192.168.x.x to any port 5050

# Enable firewall
ufw enable

# Check status
ufw status
```

---

## 📊 Useful Commands

### View Service Status
```bash
docker-compose ps
```

### View Live Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f api
docker-compose logs -f db
```

### Stop Services
```bash
docker-compose down
```

### Start Services
```bash
docker-compose up -d
```

### Restart Services
```bash
docker-compose restart
```

### Access Database Directly
```bash
docker-compose exec db psql -U paymentuser -d payment_db

# Inside psql:
SELECT * FROM orders;
SELECT * FROM transactions;
SELECT * FROM slip_verifications;
```

### View Database Backups
```bash
# Create backup
docker-compose exec db pg_dump -U paymentuser payment_db > backup.sql

# Restore backup
docker-compose exec -T db psql -U paymentuser payment_db < backup.sql
```

---

## 🐛 Troubleshooting

### Docker not installed
```bash
# Install Docker
apt-get update
apt-get install -y docker.io

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Start Docker
systemctl start docker
systemctl enable docker
```

### Port Already in Use
```bash
# Find process using port 8000
lsof -i :8000

# Kill the process
kill -9 <PID>

# Or change port in docker-compose.yml
nano docker-compose.yml
# Change: "8000:8000" to "8001:8000"
docker-compose up -d
```

### Database Connection Error
```bash
# Check database logs
docker-compose logs db

# Verify database is running
docker-compose ps db

# Restart database
docker-compose restart db
```

### Insufficient Disk Space
```bash
# Check disk usage
df -h

# Clean up Docker
docker system prune -a

# Remove old images
docker rmi $(docker images -q)
```

---

## 📈 Monitoring & Maintenance

### Regular Health Checks
```bash
# Check all services
docker-compose ps

# Check resource usage
docker stats

# Check disk space
df -h
```

### Enable Auto-Restart
Services are already configured to auto-restart in docker-compose.yml with:
```yaml
restart_policy:
  condition: on-failure
  delay: 5s
  max_attempts: 3
```

### Backup Strategy
```bash
# Weekly backup script
0 2 * * 0 /opt/promptpay-system/backup.sh

# Create backup.sh
#!/bin/bash
cd /opt/promptpay-system
docker-compose exec db pg_dump -U paymentuser payment_db | gzip > backup-$(date +%Y%m%d-%H%M%S).sql.gz
```

---

## 🔐 Security Checklist

After deployment, complete these steps:

- [ ] Change root VPS password
- [ ] Change DB_PASSWORD in .env
- [ ] Change SECRET_KEY in .env
- [ ] Set up SSL certificate
- [ ] Configure firewall rules
- [ ] Enable automatic backups
- [ ] Disable root SSH login
- [ ] Set up SSH key authentication
- [ ] Configure fail2ban for brute force protection
- [ ] Set up monitoring/alerts

---

## 📞 Support Resources

- **API Documentation**: http://150.95.84.201:8000/docs
- **Project Guide**: See VPS_DEPLOYMENT_GUIDE.md
- **Architecture**: See ARCHITECTURE.md
- **Implementation**: See IMPLEMENTATION_GUIDE.md

---

## ✨ Deployment Complete!

Your PromptPay payment system is now running on your VPS. 

Next steps:
1. ✅ Configure domain name
2. ✅ Set up SSL certificate
3. ✅ Configure firewall (restrict access if needed)
4. ✅ Set up monitoring and backups
5. ✅ Integrate with your application

🎉 System ready for production!
