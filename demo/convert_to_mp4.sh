#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "Converting demo video to MP4..."

# Check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    echo -e "${RED}❌ ffmpeg is not installed${NC}"
    echo ""
    echo "Install ffmpeg:"
    echo "  Ubuntu/Debian: sudo apt-get install ffmpeg"
    echo "  macOS: brew install ffmpeg"
    echo "  Windows: Download from https://ffmpeg.org"
    exit 1
fi

# Check if input file exists
if [ ! -f "demo_output/emass_demo.webm" ]; then
    echo -e "${RED}❌ Input file not found: demo_output/emass_demo.webm${NC}"
    echo "Please run ./run_demo.sh first to create the video"
    exit 1
fi

echo -e "${YELLOW}Converting...${NC}"

# Convert with high quality settings
ffmpeg -i demo_output/emass_demo.webm \
    -c:v libx264 \
    -preset slow \
    -crf 18 \
    -c:a aac \
    -b:a 192k \
    -movflags +faststart \
    demo_output/emass_demo.mp4 \
    -y

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ Conversion complete!${NC}"
    echo ""
    echo "Files:"
    echo "  WebM: demo_output/emass_demo.webm ($(du -h demo_output/emass_demo.webm | cut -f1))"
    echo "  MP4:  demo_output/emass_demo.mp4 ($(du -h demo_output/emass_demo.mp4 | cut -f1))"
    echo ""
    echo "The MP4 version works better with PowerPoint and other presentation software."
else
    echo -e "${RED}❌ Conversion failed${NC}"
    exit 1
fi
