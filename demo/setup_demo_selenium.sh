#!/bin/bash
set -e

echo "========================================="
echo "  TA-suhlabs-eMASS Demo Setup"
echo "  (Selenium Version)"
echo "========================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check prerequisites
echo "Checking prerequisites..."

# Check Python
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ Python 3 is required but not found${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Python 3 found${NC}"

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is required but not found${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker found${NC}"

# Check Docker Compose
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}❌ Docker Compose is required but not found${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker Compose found${NC}"

echo ""
echo "Setting up demo environment..."

# Create virtual environment for demo
echo -e "${YELLOW}Creating Python virtual environment...${NC}"
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi

# Activate virtual environment
source venv/bin/activate

# Install demo dependencies
echo -e "${YELLOW}Installing demo dependencies...${NC}"
pip install --upgrade pip > /dev/null
pip install -r requirements.txt

# Install Chrome/Chromium for Selenium
echo -e "${YELLOW}Checking for Chrome/Chromium...${NC}"
if command -v google-chrome &> /dev/null; then
    echo -e "${GREEN}✓ Google Chrome found${NC}"
elif command -v chromium-browser &> /dev/null; then
    echo -e "${GREEN}✓ Chromium found${NC}"
elif command -v chromium &> /dev/null; then
    echo -e "${GREEN}✓ Chromium found${NC}"
else
    echo -e "${YELLOW}⚠️  Chrome/Chromium not found. Installing...${NC}"
    sudo apt-get update
    sudo apt-get install -y chromium-browser chromium-chromedriver
fi

# Install ChromeDriver for Selenium
echo -e "${YELLOW}Installing ChromeDriver for Selenium...${NC}"
pip install webdriver-manager

# Install system dependencies for OpenCV
echo -e "${YELLOW}Installing system dependencies for screen recording...${NC}"
sudo apt-get install -y \
    libgl1-mesa-glx \
    libglib2.0-0 \
    python3-tk \
    scrot \
    xvfb

# Install Flask for mock API
echo -e "${YELLOW}Installing Flask for mock API...${NC}"
pip install flask requests

# Create output directory
echo -e "${YELLOW}Creating output directory...${NC}"
mkdir -p demo_output

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}  Demo Setup Complete!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "Next steps:"
echo "1. Build the TA-suhlabs-eMASS add-on:"
echo "   cd .."
echo "   make build"
echo ""
echo "2. Start the demo environment:"
echo "   cd demo"
echo "   ./run_demo_selenium.sh"
echo ""
