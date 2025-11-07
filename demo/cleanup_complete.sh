#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo -e "${RED}=========================================${NC}"
echo -e "${RED}  COMPLETE DEMO REMOVAL${NC}"
echo -e "${RED}=========================================${NC}"
echo ""
echo -e "${YELLOW}WARNING: This will completely remove the demo directory!${NC}"
echo ""
echo "This will remove:"
echo "  1. All demo files (scripts, Python code, documentation)"
echo "  2. Virtual environment and dependencies"
echo "  3. Demo output files"
echo "  4. Docker containers"
echo "  5. Playwright browser cache"
echo "  6. The entire demo/ directory"
echo ""
echo "This will NOT remove:"
echo "  - System packages (libnss3, libnspr4, etc.)"
echo "  - Docker Desktop or docker command"
echo "  - Git repository or other project files"
echo ""

read -p "Are you ABSOLUTELY sure you want to remove everything? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Removal cancelled."
    exit 0
fi

echo ""
echo -e "${YELLOW}Starting complete removal...${NC}"

# Stop Mock API
echo "1. Stopping Mock API processes..."
pkill -f "mock_emass_api.py" 2>/dev/null && echo -e "${GREEN}   ✓ Stopped${NC}" || echo "   (not running)"

# Stop Docker containers
echo "2. Stopping Docker containers..."
cd .. 2>/dev/null
if command -v docker &> /dev/null; then
    if docker compose version &> /dev/null; then
        docker compose down -v 2>/dev/null && echo -e "${GREEN}   ✓ Stopped${NC}" || echo "   (not running)"
    elif command -v docker-compose &> /dev/null; then
        docker-compose down -v 2>/dev/null && echo -e "${GREEN}   ✓ Stopped${NC}" || echo "   (not running)"
    fi
fi

# Remove Playwright cache
echo "3. Removing Playwright browser cache..."
if [ -d "$HOME/.cache/ms-playwright" ]; then
    rm -rf "$HOME/.cache/ms-playwright"
    echo -e "${GREEN}   ✓ Removed${NC}"
else
    echo "   (not found)"
fi

# Remove demo directory
echo "4. Removing demo directory..."
if [ -d "demo" ]; then
    rm -rf demo
    echo -e "${GREEN}   ✓ Demo directory removed${NC}"
else
    echo "   (not found)"
fi

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}  Complete Removal Finished!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "The demo has been completely removed from your system."
echo ""
echo "System packages (if installed) are still present:"
echo "  - libnss3, libnspr4, etc."
echo ""
echo "To remove these system packages (optional):"
echo "  Run: ./cleanup_system_packages.sh"
echo ""
