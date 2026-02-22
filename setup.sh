#!/bin/bash

# PromptPay Payment System - Setup Script

set -e

echo "================================"
echo "PromptPay Payment System Setup"
echo "================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check Python version
echo -e "${YELLOW}[1/5]${NC} Checking Python version..."
python_version=$(python3 --version 2>&1 | awk '{print $2}')
echo "Found Python $python_version"

# Create virtual environment
echo -e "${YELLOW}[2/5]${NC} Creating virtual environment..."
if [ ! -d "venv" ]; then
    python3 -m venv venv
    echo -e "${GREEN}✓${NC} Virtual environment created"
else
    echo -e "${GREEN}✓${NC} Virtual environment already exists"
fi

# Activate virtual environment
echo -e "${YELLOW}[3/5]${NC} Activating virtual environment..."
source venv/bin/activate
echo -e "${GREEN}✓${NC} Virtual environment activated"

# Install dependencies
echo -e "${YELLOW}[4/5]${NC} Installing dependencies..."
pip install -q -r requirements.txt
echo -e "${GREEN}✓${NC} Dependencies installed"

# Check Docker & start services
echo -e "${YELLOW}[5/5]${NC} Starting PostgreSQL database..."
if command -v docker-compose &> /dev/null; then
    docker-compose up -d
    echo -e "${GREEN}✓${NC} PostgreSQL started (docker-compose)"
    echo "  Wait 10 seconds for database to be ready..."
    sleep 10
else
    echo -e "${RED}✗${NC} docker-compose not found"
    echo "  Please ensure PostgreSQL is running manually"
    echo "  Or install Docker: https://docs.docker.com/get-docker/"
fi

echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo "Next steps:"
echo "1. Run the server:"
echo -e "   ${YELLOW}python main.py${NC}"
echo ""
echo "2. Access API documentation:"
echo -e "   ${YELLOW}http://localhost:8000/docs${NC}"
echo ""
echo "3. Test the endpoints:"
echo -e "   ${YELLOW}bash test_api.sh${NC}"
echo ""
