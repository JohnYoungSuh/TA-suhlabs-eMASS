#!/bin/bash
set -e

echo "========================================="
echo "  Fixing Playwright Installation"
echo "========================================="
echo ""

# Activate virtual environment
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

source venv/bin/activate

echo "Installing/updating Playwright..."
pip install --upgrade playwright

echo ""
echo "Installing Playwright browsers and system dependencies..."
echo "This may require sudo password for system dependencies..."
echo ""

# Install browsers with system dependencies
playwright install --with-deps chromium

echo ""
echo "========================================="
echo "  Playwright Fixed!"
echo "========================================="
echo ""
echo "Try running the demo again:"
echo "  ./run_demo.sh"
