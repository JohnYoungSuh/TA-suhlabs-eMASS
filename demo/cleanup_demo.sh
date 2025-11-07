#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo -e "${YELLOW}=========================================${NC}"
echo -e "${YELLOW}  Demo Cleanup Script${NC}"
echo -e "${YELLOW}=========================================${NC}"
echo ""
echo "This will remove demo-related files and stop services."
echo ""
echo "What will be cleaned up:"
echo "  - Virtual environment (venv/)"
echo "  - Demo output files (demo_output/)"
echo "  - Running Mock API process"
echo "  - Docker containers"
echo "  - Playwright browser cache"
echo ""
echo "What will NOT be removed:"
echo "  - Demo source files (*.py, *.sh, *.md)"
echo "  - System packages installed via apt-get"
echo "  - The demo/ directory itself"
echo ""

read -p "Continue with cleanup? (y/n): " CONFIRM

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo -e "${YELLOW}Starting cleanup...${NC}"

# Stop Mock API if running
echo "Stopping Mock API processes..."
pkill -f "mock_emass_api.py" 2>/dev/null && echo -e "${GREEN}✓ Mock API stopped${NC}" || echo "  (not running)"

# Stop Docker containers
echo "Stopping Docker containers..."
cd .. 2>/dev/null
if command -v docker &> /dev/null; then
    if docker compose version &> /dev/null; then
        docker compose down -v 2>/dev/null && echo -e "${GREEN}✓ Docker containers stopped${NC}" || echo "  (no containers running)"
    elif command -v docker-compose &> /dev/null; then
        docker-compose down -v 2>/dev/null && echo -e "${GREEN}✓ Docker containers stopped${NC}" || echo "  (no containers running)"
    fi
fi
cd demo 2>/dev/null

# Remove virtual environment
if [ -d "venv" ]; then
    echo "Removing virtual environment..."
    rm -rf venv
    echo -e "${GREEN}✓ Virtual environment removed${NC}"
fi

# Remove demo output
if [ -d "demo_output" ]; then
    echo "Removing demo output files..."
    rm -rf demo_output
    echo -e "${GREEN}✓ Demo output removed${NC}"
fi

# Remove Playwright cache
if [ -d "$HOME/.cache/ms-playwright" ]; then
    echo "Removing Playwright browser cache..."
    rm -rf "$HOME/.cache/ms-playwright"
    echo -e "${GREEN}✓ Playwright cache removed${NC}"
fi

# Remove Python cache
echo "Removing Python cache files..."
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null
find . -type f -name "*.pyc" -delete 2>/dev/null
echo -e "${GREEN}✓ Python cache removed${NC}"

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}  Cleanup Complete!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "Cleaned up:"
echo "  ✓ Virtual environment"
echo "  ✓ Demo output files"
echo "  ✓ Docker containers"
echo "  ✓ Playwright cache"
echo "  ✓ Python cache"
echo ""
echo "Demo source files are still in the demo/ directory."
echo ""
