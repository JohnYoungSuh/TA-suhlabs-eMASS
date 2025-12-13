#!/bin/bash
# Fix setup script - ensures we're in WSL and recreates venv properly

set -e

echo "=================================="
echo "  WSL Environment Setup Fixer"
echo "=================================="
echo ""

# Verify we're in WSL/Linux
if [[ ! -f /proc/version ]] || ! grep -qi linux /proc/version; then
    echo "❌ ERROR: This script must be run in WSL/Linux, not PowerShell!"
    echo ""
    echo "To run this script:"
    echo "  1. Open WSL terminal (type 'wsl' in PowerShell)"
    echo "  2. cd ~/projects/suhlabs/TA-suhlabs-eMASS"
    echo "  3. bash fix_setup.sh"
    exit 1
fi

echo "✓ Running in WSL/Linux environment"
echo ""

# Check Python version
echo "Checking Python installation..."
if ! command -v python3 &> /dev/null; then
    echo "❌ ERROR: python3 not found!"
    echo "Install with: sudo apt-get update && sudo apt-get install python3 python3-venv python3-pip"
    exit 1
fi

PYTHON_VERSION=$(python3 --version)
echo "✓ Found: $PYTHON_VERSION"
echo ""

# Check if python3.12 is available
if command -v python3.12 &> /dev/null; then
    PYTHON_CMD="python3.12"
    echo "✓ Using python3.12"
else
    PYTHON_CMD="python3"
    echo "⚠️  python3.12 not found, using python3"
fi
echo ""

# Remove old venv if it exists
if [ -d ".venv" ]; then
    echo "Removing old .venv directory..."
    rm -rf .venv
    echo "✓ Old venv removed"
    echo ""
fi

# Create fresh venv
echo "Creating new virtual environment..."
$PYTHON_CMD -m venv .venv
echo "✓ Virtual environment created"
echo ""

# Verify venv works
if [ ! -f ".venv/bin/pip" ]; then
    echo "❌ ERROR: venv creation failed - pip not found"
    exit 1
fi

echo "✓ Virtual environment is valid"
echo ""

# Activate and upgrade pip
echo "Upgrading pip..."
source .venv/bin/activate
pip install --upgrade pip setuptools wheel
echo "✓ pip upgraded"
echo ""

# Install requirements
if [ -f "requirements.txt" ]; then
    echo "Installing requirements..."
    pip install -r requirements.txt
    echo "✓ Requirements installed"
else
    echo "⚠️  No requirements.txt found, skipping"
fi

echo ""
echo "=================================="
echo "  Setup Complete!"
echo "=================================="
echo ""
echo "Virtual environment is ready at: .venv/"
echo ""
echo "To use it:"
echo "  source .venv/bin/activate"
echo ""
echo "Or run make commands directly:"
echo "  make build"
echo "  make validate"
echo ""
