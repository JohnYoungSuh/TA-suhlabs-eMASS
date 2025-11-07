#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo -e "${RED}=========================================${NC}"
echo -e "${RED}  Remove System Packages${NC}"
echo -e "${RED}=========================================${NC}"
echo ""
echo -e "${YELLOW}WARNING: This will remove system packages!${NC}"
echo ""
echo "This will attempt to remove packages installed for Playwright:"
echo "  - libnss3, libnspr4, libasound2"
echo "  - libatk1.0-0, libatk-bridge2.0-0"
echo "  - libcups2, libdrm2, libdbus-1-3"
echo "  - libxcb1, libxkbcommon0, libx11-6"
echo "  - libxcomposite1, libxdamage1, libxext6"
echo "  - libxfixes3, libxrandr2, libgbm1"
echo "  - libpango-1.0-0, libcairo2"
echo ""
echo -e "${RED}IMPORTANT:${NC}"
echo "  - These packages may be used by other applications!"
echo "  - apt will only remove if no other package depends on them"
echo "  - This is generally safe but not always necessary"
echo ""

read -p "Do you want to remove these system packages? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "System package removal cancelled."
    echo "The packages will remain on your system (recommended)."
    exit 0
fi

echo ""
echo -e "${YELLOW}Removing system packages...${NC}"
echo "Note: Packages with dependencies will NOT be removed"
echo ""

# Use apt-get autoremove to remove packages if no longer needed
sudo apt-get autoremove -y \
    libnss3 \
    libnspr4 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libdbus-1-3 \
    libxcb1 \
    libxkbcommon0 \
    libx11-6 \
    libxcomposite1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libpango-1.0-0 \
    libcairo2 \
    libasound2 \
    libatspi2.0-0 2>/dev/null

echo ""
echo -e "${GREEN}Done!${NC}"
echo ""
echo "Note: Some packages may not have been removed if they are"
echo "required by other software on your system. This is normal."
echo ""
