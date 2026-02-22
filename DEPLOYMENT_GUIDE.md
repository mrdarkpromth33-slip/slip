# Deployment Guide - PromptPay Payment System

## 🚀 Deployment Options

### Option 1: Local Development (Recommended for Starting)

See [QUICK_START.md](QUICK_START.md) for setup instructions.

```bash
# 1. Clone and setup
git clone <repo>
cd slip
bash setup.sh

# 2. Start server
source venv/bin/activate
python main.py

# 3. Access at http://localhost:8000
```

---

### Option 2: Docker Deployment (Recommended for Production)

#### Prerequisites
- Docker 20.10+
- Docker Compose 2.0+
- 2GB+ disk space for images/volumes

#### Step 1: Start All Services
```bash
docker-compose up -d
```

This starts:
- **PostgreSQL** (port 5432)
- **pgAdmin** (port 5050) - Database management UI
- **FastAPI** (port 8000) - Payment API

#### Step 2: Verify Services
```bash
docker-compose ps
docker-compose logs api
```

#### Step 3: Access Services
- API: http://localhost:8000
- API Docs: http://localhost:8000/docs
- pgAdmin: http://localhost:5050 (admin@example.com / admin)

#### Step 4: Stop Services
```bash
docker-compose down    # Stop but keep data
docker-compose down -v # Stop and remove volumes
```

---

### Option 3: Production Kubernetes Deployment

#### Create ConfigMap for Secrets
```bash
kubectl create secret generic slip-secrets \
  --from-literal=DATABASE_URL=postgresql://user:pass@postgres:5432/slip_db
```

#### Deploy PostgreSQL
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:15-alpine
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_USER
          value: slip_user
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: slip-secrets
              key: db-password
        - name: POSTGRES_DB
          value: slip_db
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi
```

#### Deploy API
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: slip-api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: slip-api
  template:
    metadata:
      labels:
        app: slip-api
    spec:
      containers:
      - name: slip-api
        image: slip:latest
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: slip-secrets
              key: DATABASE_URL
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
```

#### Create Service
```yaml
apiVersion: v1
kind: Service
metadata:
  name: slip-api
spec:
  type: LoadBalancer
  selector:
    app: slip-api
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8000
```

---

### Option 4: Linux VPS/Cloud Server Deployment

#### Step 1: SSH to Server
```bash
ssh user@your-server.com
```

#### Step 2: Install Dependencies
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y python3.10 python3-pip \
  postgresql postgresql-contrib docker.io docker-compose

# Add user to docker group
sudo usermod -aG docker $USER
```

#### Step 3: Clone Repository
```bash
cd /opt
git clone <repo> slip
cd slip
```

#### Step 4: Setup Environment
```bash
# Create .env for production
cat > .env << EOF
DATABASE_URL=postgresql://slip_user:STRONG_PASSWORD@localhost:5432/slip_db
DEBUG=False
HOST=0.0.0.0
PORT=8000
EOF

# Secure permissions
chmod 600 .env
```

#### Step 5: Start Services
```bash
# Using docker-compose
docker-compose up -d

# Or without Docker (manual setup)
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
gunicorn main:app -w 4 -b 0.0.0.0:8000
```

#### Step 6: Setup Reverse Proxy (Nginx)
```nginx
server {
    listen 80;
    server_name api.example.com;
    
    # Redirect to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.example.com;
    
    ssl_certificate /etc/letsencrypt/live/api.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.example.com/privkey.pem;
    
    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support (if using WebSocket in future)
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

#### Step 7: Install SSL Certificate (Let's Encrypt)
```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot certonly -d api.example.com
```

#### Step 8: Setup Systemd Service
```bash
# Create service file
sudo tee /etc/systemd/system/slip-api.service << EOF
[Unit]
Description=PromptPay Payment API
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=/opt/slip
Environment="PATH=/opt/slip/venv/bin"
ExecStart=/opt/slip/venv/bin/gunicorn main:app -w 4 -b 0.0.0.0:8000
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable slip-api
sudo systemctl start slip-api
```

---

## 📊 Performance Tuning

### Database Connection Pool
Edit `database.py`:
```python
engine = create_engine(
    settings.DATABASE_URL,
    pool_size=20,           # Increase for production
    max_overflow=40,        # Connection overflow
    pool_pre_ping=True,     # Check connections before use
)
```

### Gunicorn Worker Configuration
```bash
# 4 workers + 4 threads per worker
gunicorn main:app -w 4 -k uvicorn.workers.UvicornWorker --threads 4
```

### PostgreSQL Optimization
```sql
-- Connection pooling
ALTER SYSTEM SET max_connections = 200;

-- Increase work memory
ALTER SYSTEM SET work_mem = '256MB';

-- Enable query parallelization
ALTER SYSTEM SET max_parallel_workers = 4;

-- Apply changes
SELECT pg_reload_conf();
```

---

## 📈 Scaling Strategies

### Horizontal Scaling (Multiple Servers)
```
Load Balancer
    ├── API Server 1 (Nginx reverse proxy)
    ├── API Server 2 (Nginx reverse proxy)
    └── API Server 3 (Nginx reverse proxy)
         ↓
    PostgreSQL (Shared)
```

Use Nginx upstream:
```nginx
upstream api_backend {
    server api1.example.com:8000;
    server api2.example.com:8000;
    server api3.example.com:8000;
}

server {
    location / {
        proxy_pass http://api_backend;
    }
}
```

### Caching Layer
Add Redis for session/cache:
```bash
docker run -d -p 6379:6379 redis:latest
```

Update code to use Redis:
```python
from redis import Redis
cache = Redis(host='localhost', port=6379)
```

### Database Replication
Set up PostgreSQL read replicas for load distribution.

---

## 🔍 Monitoring & Logging

### Application Logging
```python
# main.py - Configure structured logging
import logging
import json

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Log with context
logger.info("Payment generated", extra={
    "order_id": order.order_id,
    "amount": order.amount,
    "timestamp": datetime.utcnow().isoformat()
})
```

### Docker Logs
```bash
docker-compose logs -f api
docker logs -f slip_api
```

### Systemd Logs
```bash
journalctl -u slip-api -f
```

### Prometheus Monitoring (Optional)
```python
from prometheus_client import Counter, Histogram
import time

payment_counter = Counter('payments_total', 'Total payments processed')
processing_time = Histogram('payment_processing_seconds', 'Payment processing time')

@payment_counter.count_exceptions()
@processing_time.time()
def process_payment(order):
    # Implementation
    pass
```

---

## 🔐 Security Checklist

- [ ] Update `.env` with strong `DATABASE_URL` password
- [ ] Change default PostgreSQL password
- [ ] Enable HTTPS/SSL
- [ ] Set `DEBUG=False` in `.env`
- [ ] Add API authentication (JWT/API keys)
- [ ] Configure CORS properly
- [ ] Set up firewall rules
- [ ] Enable database backups
- [ ] Implement rate limiting
- [ ] Add request logging
- [ ] Secure file upload directory
- [ ] Validate all inputs
- [ ] Use environment variables for secrets
- [ ] Implement API versioning
- [ ] Add request signing for webhooks

---

## 💾 Database Backups

### PostgreSQL Backup
```bash
# Dump database
pg_dump -U slip_user -h localhost slip_db > backup.sql

# Restore from backup
psql -U slip_user -h localhost slip_db < backup.sql

# Automated daily backup
0 2 * * * pg_dump -U slip_user slip_db | gzip > /backups/slip_$(date +\%Y\%m\%d).sql.gz
```

### Docker Volume Backup
```bash
docker run --rm -v slip_postgres_data:/data -v $(pwd):/backup \
  postgres:15-alpine tar czf /backup/postgres_backup.tar.gz /data
```

---

## 🆘 Troubleshooting Deployment

| Problem | Solution |
|---------|----------|
| Port 8000 already in use | `lsof -i :8000` then `kill -9 <PID>` |
| Database connection failed | Check `/etc/postgresql` for config |
| Out of memory | Increase swap: `fallocate -l 4G /swapfile` |
| High CPU usage | Check slow queries: `EXPLAIN ANALYZE` |
| Disk space full | `docker system prune -a` to clean images |

---

## 📞 Getting Help

1. Check logs: `docker-compose logs api`
2. Test database: `psql -U slip_user -d slip_db -c "SELECT 1"`
3. Test API: `curl http://localhost:8000/health`
4. Read documentation: [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md)

---

**Deployment Version: 1.0.0**
**Last Updated: 2024-01-15**
