#!/bin/bash
set -e

echo "=================================="
echo "  Full Rebuild Script"
echo "=================================="
echo ""

# Pull latest changes
echo "Step 1: Pulling latest changes..."
git pull

# Clean output
echo ""
echo "Step 2: Cleaning output directory..."
sudo rm -rf output/

# Build add-on
echo ""
echo "Step 3: Building add-on..."
make build

# Rebuild Docker
echo ""
echo "Step 4: Stopping Docker containers..."
docker compose down -v

echo ""
echo "Step 5: Rebuilding Docker image (no cache)..."
docker compose build --no-cache

echo ""
echo "Step 6: Starting Docker containers..."
docker compose up -d

echo ""
echo "Step 7: Waiting for Splunk to start (30 seconds)..."
sleep 30

echo ""
echo "=================================="
echo "  Rebuild Complete!"
echo "=================================="
echo ""
echo "Watching logs (Ctrl+C to exit)..."
echo ""
docker logs -f splunk-emass | grep -i emass
