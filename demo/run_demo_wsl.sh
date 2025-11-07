#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}  TA-securepro-eMASS Demo (WSL Mode)${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""
echo "Running in WSL with Docker Desktop..."
echo ""

# Check if running in WSL
if ! grep -qi microsoft /proc/version; then
    echo -e "${YELLOW}⚠️  Warning: This doesn't appear to be WSL${NC}"
    echo "This script is optimized for WSL + Docker Desktop."
    read -p "Continue anyway? (y/n): " CONTINUE
    if [ "$CONTINUE" != "y" ]; then
        exit 0
    fi
fi

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker not found${NC}"
    echo ""
    echo "Make sure Docker Desktop is running and WSL integration is enabled:"
    echo "  1. Open Docker Desktop"
    echo "  2. Settings → Resources → WSL Integration"
    echo "  3. Enable for your distro"
    exit 1
fi

# Check if Docker daemon is running
if ! docker ps &> /dev/null; then
    echo -e "${RED}❌ Cannot connect to Docker${NC}"
    echo ""
    echo "Make sure Docker Desktop is running on Windows!"
    exit 1
fi
echo -e "${GREEN}✓ Docker Desktop connected${NC}"

# Check if venv exists
if [ ! -d "venv" ]; then
    echo -e "${RED}❌ Virtual environment not found${NC}"
    echo ""
    echo "Please run setup first:"
    echo "  ./setup_demo.sh"
    echo "  source venv/bin/activate"
    echo "  playwright install chromium"
    exit 1
fi

# Check if add-on is built
if [ ! -d "../output/TA-securepro-eMASS" ]; then
    echo -e "${YELLOW}⚠️  Add-on not built. Building now...${NC}"
    cd ..
    make build
    cd demo
fi

# Activate virtual environment
source venv/bin/activate
echo -e "${GREEN}✓ Virtual environment activated${NC}"

# Check if Playwright is installed
if ! python -c "import playwright" 2>/dev/null; then
    echo -e "${RED}❌ Playwright not installed${NC}"
    echo "Installing Playwright..."
    pip install playwright
    playwright install chromium
fi

echo ""
echo -e "${YELLOW}Step 1: Starting Mock eMASS API in WSL...${NC}"
# Start mock API in background
python mock_emass_api.py &
MOCK_API_PID=$!
echo -e "${GREEN}✓ Mock API started (PID: $MOCK_API_PID)${NC}"

# Wait for mock API to be ready
echo -e "${YELLOW}Waiting for Mock API to be ready...${NC}"
for i in {1..10}; do
    if curl -s http://localhost:4010/health > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Mock API is ready${NC}"
        break
    fi
    if [ $i -eq 10 ]; then
        echo -e "${RED}❌ Mock API failed to start${NC}"
        kill $MOCK_API_PID 2>/dev/null || true
        exit 1
    fi
    sleep 1
done

echo ""
echo -e "${YELLOW}Step 2: Starting Splunk in Docker Desktop...${NC}"
cd ..

# Detect docker compose command
if docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
elif command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    echo -e "${RED}❌ docker compose not found${NC}"
    cd demo
    kill $MOCK_API_PID 2>/dev/null || true
    exit 1
fi

# Stop any existing containers
echo "Stopping any existing containers..."
$DOCKER_COMPOSE down -v 2>/dev/null || true

# Start Splunk
echo "Starting Splunk container..."
$DOCKER_COMPOSE up -d

echo ""
echo -e "${YELLOW}Waiting for Splunk to be ready (this takes 2-3 minutes)...${NC}"
echo "Docker is starting Splunk 9.2.1 with TA-securepro-eMASS installed..."

SPLUNK_READY=false
for i in {1..60}; do
    if curl -s -k https://localhost:8089/services/server/info -u admin:Password123! > /dev/null 2>&1; then
        echo ""
        echo -e "${GREEN}✓ Splunk is ready!${NC}"
        SPLUNK_READY=true
        break
    fi
    echo -n "."
    sleep 3
done

if [ "$SPLUNK_READY" = false ]; then
    echo ""
    echo -e "${RED}❌ Splunk failed to start in time${NC}"
    echo ""
    echo "Check Docker logs:"
    echo "  docker logs splunk-emass"
    cd demo
    kill $MOCK_API_PID 2>/dev/null || true
    exit 1
fi

# Wait a bit more for UI to be fully ready
echo -e "${YELLOW}Waiting for Splunk UI to be fully ready...${NC}"
sleep 10

cd demo

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}  Environment Ready!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "Services running:"
echo -e "  ${GREEN}✓${NC} Mock eMASS API: http://localhost:4010 (WSL)"
echo -e "  ${GREEN}✓${NC} Splunk: http://localhost:8000 (Docker Desktop)"
echo ""
echo -e "${BLUE}Step 3: Creating Demo Video (Headless Mode)...${NC}"
echo ""
echo "Running browser automation in headless mode..."
echo "(This is automatic in WSL since there's no display)"
echo ""

# Create output directory
mkdir -p demo_output

# Run demo in headless mode (required for WSL)
python create_demo_video.py --headless

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}  Demo Complete!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""

# Show video file info
if [ -f "demo_output/emass_demo.webm" ]; then
    VIDEO_SIZE=$(du -h demo_output/emass_demo.webm | cut -f1)
    echo -e "${GREEN}✓ Demo video created successfully!${NC}"
    echo ""
    echo "Video details:"
    echo "  File: demo_output/emass_demo.webm"
    echo "  Size: $VIDEO_SIZE"
    echo "  No watermarks ✓"
    echo ""
    echo "WSL path:"
    echo "  $(pwd)/demo_output/emass_demo.webm"
    echo ""
    echo "Windows path (open in Explorer):"
    echo "  \\\\wsl\$\\$(grep -oP '(?<=DISTRIB_ID=).*' /etc/lsb-release 2>/dev/null || echo 'Ubuntu')$(pwd | sed 's/\//\\/g')\\demo_output\\emass_demo.webm"
    echo ""
    echo "To copy to Windows Downloads folder:"
    echo "  cp demo_output/emass_demo.webm /mnt/c/Users/\$USER/Downloads/"
    echo ""
    echo "To convert to MP4 (better for PowerPoint):"
    echo "  ./convert_to_mp4.sh"
else
    echo -e "${RED}❌ Video file not found${NC}"
    echo ""
    echo "Check for errors above. Common issues:"
    echo "  - Playwright not installed: playwright install chromium"
    echo "  - Missing dependencies: sudo apt-get install libnss3 libnspr4 libasound2"
fi

echo ""
read -p "Do you want to stop the services? (y/n): " STOP_SERVICES

if [ "$STOP_SERVICES" = "y" ] || [ "$STOP_SERVICES" = "Y" ]; then
    echo -e "${YELLOW}Stopping services...${NC}"
    cd ..
    $DOCKER_COMPOSE down
    cd demo
    kill $MOCK_API_PID 2>/dev/null || true
    echo -e "${GREEN}✓ Services stopped${NC}"
else
    echo ""
    echo -e "${YELLOW}Services are still running:${NC}"
    echo "  Mock API (PID: $MOCK_API_PID)"
    echo "  Splunk (Docker container)"
    echo ""
    echo "To stop them later:"
    echo "  kill $MOCK_API_PID"
    echo "  cd .. && $DOCKER_COMPOSE down"
fi

echo ""
echo -e "${GREEN}Done!${NC}"
echo ""
echo "Your demo video is ready to show to your manager!"
