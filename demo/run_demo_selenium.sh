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
echo -e "${BLUE}  TA-suhlabs-eMASS Demo Video Creator${NC}"
echo -e "${BLUE}  (Selenium Version)${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Check if venv exists
if [ ! -d "venv" ]; then
    echo -e "${RED}❌ Virtual environment not found. Please run ./setup_demo_selenium.sh first${NC}"
    exit 1
fi

# Check if add-on is built
if [ ! -d "../output/TA-suhlabs-eMASS" ]; then
    echo -e "${RED}❌ Add-on not built. Please build it first:${NC}"
    echo "  cd .."
    echo "  make build"
    echo "  cd demo"
    exit 1
fi

# Activate virtual environment
source venv/bin/activate

echo -e "${YELLOW}Step 1: Starting Mock eMASS API...${NC}"
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
echo -e "${YELLOW}Step 2: Starting Splunk with TA-suhlabs-eMASS...${NC}"
# Use docker-compose from parent directory
cd ..

# Check which docker-compose command to use
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    DOCKER_COMPOSE="docker compose"
fi

# Start Splunk (don't destroy existing container, just ensure it's running)
$DOCKER_COMPOSE up -d

echo -e "${YELLOW}Waiting for Splunk to be ready (this may take 2-3 minutes)...${NC}"
for i in {1..60}; do
    if curl -s -k https://localhost:8089/services/server/info -u admin:Password123! > /dev/null 2>&1; then
        echo ""
        echo -e "${GREEN}✓ Splunk management API is ready${NC}"
        break
    fi
    if [ $i -eq 60 ]; then
        echo ""
        echo -e "${RED}❌ Splunk failed to start${NC}"
        cd demo
        kill $MOCK_API_PID 2>/dev/null || true
        exit 1
    fi
    echo -n "."
    sleep 3
done

# Wait for Web UI to be fully ready
echo -e "${YELLOW}Waiting for Splunk Web UI to be fully ready...${NC}"
WEB_UI_READY=false
for i in {1..30}; do
    if curl -s http://localhost:8000 > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Splunk Web UI is ready!${NC}"
        WEB_UI_READY=true
        break
    fi
    echo -n "."
    sleep 2
done

if [ "$WEB_UI_READY" = false ]; then
    echo ""
    echo -e "${YELLOW}⚠️  Web UI check timed out, but continuing anyway...${NC}"
fi

# Extra buffer time to ensure everything is stable
echo -e "${YELLOW}Waiting extra 15 seconds for UI to stabilize...${NC}"
sleep 15

cd demo

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}  Environment Ready!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo -e "Services running:"
echo -e "  ${GREEN}✓${NC} Mock eMASS API: http://localhost:4010"
echo -e "  ${GREEN}✓${NC} Splunk: http://localhost:8000 (admin/Password123!)"
echo ""
echo -e "${BLUE}Step 3: Creating Demo Video with Selenium...${NC}"
echo ""

# Check if running in WSL
if grep -qi microsoft /proc/version; then
    echo -e "${YELLOW}⚠️  WSL detected${NC}"
    echo "For WSL, you'll need X server (like VcXsrv) for visible mode."
    echo "Headless mode is recommended for WSL."
    echo ""
fi

# Ask user for recording mode
echo "Recording mode:"
echo "  1) Visible (watch the demo being created)"
echo "  2) Headless (background recording)"
read -p "Select mode (1 or 2): " MODE

if [ "$MODE" = "2" ]; then
    python create_demo_video_selenium.py --headless
else
    python create_demo_video_selenium.py
fi

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}  Demo Complete!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""

# Show video file info
if [ -f "demo_output/emass_demo.avi" ]; then
    VIDEO_SIZE=$(du -h demo_output/emass_demo.avi | cut -f1)
    echo -e "${GREEN}✓ Demo video created successfully!${NC}"
    echo ""
    echo "Video details:"
    echo "  File: demo_output/emass_demo.avi"
    echo "  Size: $VIDEO_SIZE"
    echo "  No watermarks ✓"
    echo ""
    echo "You can now show this video to your manager!"
    echo ""
    echo "To convert to MP4 (better compatibility):"
    echo "  ffmpeg -i demo_output/emass_demo.avi -c:v libx264 -crf 23 -c:a aac demo_output/emass_demo.mp4"
else
    echo -e "${RED}❌ Video file not found${NC}"
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
    echo -e "${YELLOW}Services are still running. To stop them later:${NC}"
    echo "  cd .. && $DOCKER_COMPOSE down"
    echo "  kill $MOCK_API_PID"
fi

echo ""
echo -e "${GREEN}Done!${NC}"
