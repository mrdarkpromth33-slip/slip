# Quick Fix: Start PromptPay Services

Your VPS has a PostgreSQL service running that conflicts with Docker. Here's the fix:

## Option 1: Manual Fix (Fastest)

SSH to your VPS and run:

```bash
# Kill the existing PostgreSQL
sudo pkill -9 postgres

# Wait a second
sleep 1

# Restart docker daemon
sudo systemctl restart docker

# Go to the system directory
cd /opt/promptpay-system

# Stop any existing containers
docker-compose down -v

# Start fresh
docker-compose up -d

# Wait for services to start
sleep 5

# Check status
docker ps

# Test the API
curl http://localhost:8000/docs
```

## Option 2: Using the Script

Save this as `fix-services.sh` on your local machine, then run:

```bash
chmod +x fix-services.sh
./fix-services.sh root@150.95.84.201
```

## What This Does

1. **Kills PostgreSQL**: Removes the conflicting PostgreSQL service
2. **Restarts Docker**: Ensures Docker daemon is clean
3. **Stops Old Containers**: Removes any stale containers
4. **Starts Fresh Containers**: Brings up the 3 services:
   - `slip_api` - FastAPI on port 8000
   - `slip_postgres` - PostgreSQL on port 5432  
   - `slip_pgadmin` - pgAdmin on port 5050

## Verify Services

After running the fix, check:

### Web Browser
- API Docs: http://150.95.84.201:8000/docs
- Database UI: http://150.95.84.201:5050 (admin@example.com / admin)

### From VPS Console
```bash
# See all running containers
docker ps

# Check API logs
docker-compose logs slip_api --tail=20

# Test API directly
curl http://localhost:8000/docs | head -20
```

### From Your Local Machine
```bash
# Test the API endpoint
curl -X POST http://150.95.84.201:8000/api/payment/generate-qr \
  -H "Content-Type: application/json" \
  -d '{"amount": 100}'
```

## Expected Output

When services are running correctly:

```
CONTAINER ID   IMAGE                     COMMAND                  CREATED         STATUS         PORTS
abc123...      promptpay-system-api      "uvicorn main:app --…    5 seconds ago   Up 3 seconds   0.0.0.0:8000->8000/tcp
def456...      postgres:15-alpine        "docker-entrypoint.s…    5 seconds ago   Up 3 seconds   0.0.0.0:5432->5432/tcp
ghi789...      dpage/pgadmin4:latest     "/entrypoint.sh"         5 seconds ago   Up 2 seconds   0.0.0.0:5050->80/tcp
```

## If It Still Fails

Check what's using the ports:

```bash
# See what's on port 5432
sudo lsof -i :5432

# Or remove all docker containers and try again
docker rm -f $(docker ps -aq)
docker-compose up -d
```

