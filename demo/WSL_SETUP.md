# Running Demo on WSL + Docker Desktop

This guide is for running the demo on **Windows Subsystem for Linux (WSL)** with **Docker Desktop**.

## Architecture

```
┌─────────────────────────────────────────┐
│  Windows                                │
│  ├─ Docker Desktop (runs containers)   │
│  │  ├─ Splunk (port 8000, 8089)       │
│  │  └─ Mock eMASS API (port 4010)     │
│  └─ WSL (Ubuntu/Debian)                │
│     └─ Playwright (browser automation) │
└─────────────────────────────────────────┘
```

## Prerequisites

### 1. Docker Desktop on Windows
- Docker Desktop must be running
- WSL integration must be enabled:
  - Open Docker Desktop
  - Settings → Resources → WSL Integration
  - Enable integration for your WSL distro

### 2. Verify Docker Works in WSL

```bash
# In WSL terminal
docker --version
docker ps
```

Both commands should work without errors.

## Setup Steps

### 1. Install System Dependencies in WSL

```bash
cd /home/suhlabs/projects/suhlabs/TA-suhlabs-eMASS/demo

# Install required packages
sudo apt-get update
sudo apt-get install -y \
    python3-pip \
    python3-venv \
    curl

# Install Playwright dependencies
sudo apt-get install -y \
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
    libasound2
```

### 2. Setup Demo Environment

```bash
cd /home/suhlabs/projects/suhlabs/TA-suhlabs-eMASS/demo

# Run setup script
./setup_demo.sh

# Activate virtual environment
source venv/bin/activate

# Install Playwright browser (headless)
playwright install chromium
```

### 3. Build the Add-on

```bash
cd /home/suhlabs/projects/suhlabs/TA-suhlabs-eMASS
make build
cd demo
```

## Running the Demo

### Option 1: Use the Simplified WSL Script

```bash
cd /home/suhlabs/projects/suhlabs/TA-suhlabs-eMASS/demo
./run_demo_wsl.sh
```

This script automatically:
- Runs in headless mode (no GUI needed)
- Uses Docker Desktop on Windows
- Handles WSL networking

### Option 2: Manual Steps

```bash
cd /home/suhlabs/projects/suhlabs/TA-suhlabs-eMASS/demo

# Activate venv
source venv/bin/activate

# Start Mock API
python mock_emass_api.py &
MOCK_PID=$!

# Start Docker containers (Docker Desktop on Windows)
cd ..
docker compose up -d
cd demo

# Wait for Splunk to start (2-3 minutes)
sleep 120

# Create video (HEADLESS MODE for WSL)
python create_demo_video.py --headless

# Stop services
cd ..
docker compose down
kill $MOCK_PID
```

## Important Notes for WSL

### 1. Always Use Headless Mode

WSL doesn't have a display server by default, so always use `--headless` flag:

```bash
python create_demo_video.py --headless
```

### 2. Networking Between WSL and Docker Desktop

- Docker Desktop exposes ports to `localhost` on Windows
- WSL2 can access them via `localhost` (shared networking)
- URLs like `http://localhost:8000` work from WSL to reach Docker containers

### 3. File Paths

Your demo video will be saved in WSL:
```
/home/suhlabs/projects/suhlabs/TA-suhlabs-eMASS/demo/demo_output/emass_demo.webm
```

To access from Windows Explorer:
```
\\wsl$\Ubuntu\home\suhlabs\projects\suhlabs\TA-suhlabs-eMASS\demo\demo_output\emass_demo.webm
```

Or copy to Windows:
```bash
cp demo_output/emass_demo.webm /mnt/c/Users/YourUsername/Downloads/
```

## Troubleshooting WSL-Specific Issues

### Issue: "Cannot connect to Docker daemon"

**Solution:** Ensure Docker Desktop WSL integration is enabled:
1. Open Docker Desktop
2. Settings → Resources → WSL Integration
3. Enable for your distro
4. Restart WSL: `wsl --shutdown` (in Windows PowerShell)

### Issue: "localhost:8000 connection refused"

**Solution:** Wait longer for Splunk to start:
```bash
# Check if Splunk is running
docker ps

# Check Splunk logs
docker logs splunk-emass

# Wait and retry
sleep 60
```

### Issue: Playwright display errors

**Solution:** Make sure you're using headless mode:
```bash
python create_demo_video.py --headless
```

### Issue: "No such file or directory" for video output

**Solution:** Ensure output directory exists:
```bash
mkdir -p demo_output
```

## Performance Tips

1. **Allocate more resources to WSL** (in `.wslconfig`):
   ```
   # Create/edit: C:\Users\YourUsername\.wslconfig
   [wsl2]
   memory=4GB
   processors=2
   ```

2. **Keep Docker Desktop running** - Don't close it during demo creation

3. **Close unnecessary Windows apps** - Free up RAM for Docker

## Converting Video to MP4 (for Windows apps)

After creating the video, convert to MP4 for better compatibility with PowerPoint:

```bash
# In WSL
cd /home/suhlabs/projects/suhlabs/TA-suhlabs-eMASS/demo

# Install ffmpeg if not installed
sudo apt-get install ffmpeg

# Convert
./convert_to_mp4.sh

# Copy to Windows Downloads
cp demo_output/emass_demo.mp4 /mnt/c/Users/YourUsername/Downloads/
```

## Quick Reference

```bash
# Setup (one time)
cd /home/suhlabs/projects/suhlabs/TA-suhlabs-eMASS/demo
./setup_demo.sh
source venv/bin/activate
playwright install chromium

# Build add-on
cd ..
make build
cd demo

# Create demo video (WSL mode)
./run_demo_wsl.sh

# Or manually with headless mode
python create_demo_video.py --headless

# Copy to Windows
cp demo_output/emass_demo.webm /mnt/c/Users/YourUsername/Downloads/
```

## Success Checklist

- [ ] Docker Desktop is running on Windows
- [ ] WSL integration enabled in Docker Desktop
- [ ] `docker ps` works in WSL
- [ ] System dependencies installed (`sudo apt-get install...`)
- [ ] Virtual environment created and activated
- [ ] Playwright browser installed (`playwright install chromium`)
- [ ] Add-on built (`make build`)
- [ ] Using headless mode (`--headless` flag)

If all checkboxes are checked, the demo should work!
