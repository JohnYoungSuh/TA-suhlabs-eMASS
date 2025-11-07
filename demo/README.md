# TA-securepro-eMASS Demo Video Creator

Automated demo video creation for the TA-securepro-eMASS Splunk add-on. Creates professional demonstration videos **without watermarks** showing the configuration and data collection capabilities.

## Features

✅ **No Watermarks** - Uses open-source Playwright for browser automation
✅ **Fully Automated** - No manual recording needed
✅ **High Quality** - 1920x1080 HD video output
✅ **Realistic Demo** - Mock eMASS API with sample POA&M data
✅ **Fast** - Complete demo video in ~2-3 minutes

## What the Demo Shows

The automated demo video demonstrates:

1. **Login to Splunk** - Authenticates to Splunk Web UI
2. **Navigate to Add-on Configuration** - Opens TA-securepro-eMASS configuration page
3. **Configure Account** - Sets up eMASS account with:
   - Account name
   - **System ID: 55090** (clearly visible)
   - Base URL for eMASS API
   - API Key (encrypted)
   - Default index
4. **Configure Data Input** - Creates POA&M data collection input
5. **View Collected Data** - Searches for and displays POA&M events in Splunk
6. **Show Event Details** - Expands event to show POA&M fields

## Prerequisites

### Software Requirements

- Python 3.7+
- Docker and Docker Compose
- 4GB+ available RAM
- 2GB+ available disk space

### System Requirements

- Linux, macOS, or Windows with WSL2
- Internet connection (for initial setup to download dependencies)

## Quick Start

### 1. Setup Demo Environment

```bash
cd demo
chmod +x setup_demo.sh run_demo.sh
./setup_demo.sh
```

This will:
- Create a Python virtual environment
- Install Playwright and Flask
- Download Chromium browser for automation
- Set up demo directories

### 2. Build the Add-on

```bash
cd ..
make build
cd demo
```

### 3. Run the Demo

```bash
./run_demo.sh
```

This will:
1. Start Mock eMASS API server
2. Start Splunk with TA-securepro-eMASS installed
3. Wait for services to be ready
4. Run automated browser script to create video
5. Save video to `demo_output/emass_demo.webm`

**Recording Modes:**
- **Visible Mode** - Watch the browser automation in real-time (recommended first time)
- **Headless Mode** - Background recording, faster and no UI needed

## Output

### Video File

- **Location**: `demo/demo_output/emass_demo.webm`
- **Format**: WebM (VP9 video codec)
- **Resolution**: 1920x1080 (Full HD)
- **Duration**: ~2-3 minutes
- **Size**: ~10-20 MB

### Converting to MP4

For better compatibility with presentation software (PowerPoint, Keynote):

```bash
# Install ffmpeg if not already installed
# Ubuntu/Debian: sudo apt-get install ffmpeg
# macOS: brew install ffmpeg

# Convert to MP4
ffmpeg -i demo_output/emass_demo.webm -c:v libx264 -crf 23 -c:a aac demo_output/emass_demo.mp4
```

## Architecture

### Components

```
┌─────────────────────────────────────────────────────┐
│  Demo Video Creator (Playwright automation)         │
│  - Browser automation                               │
│  - Screen recording                                 │
│  - Slow-motion actions for visibility               │
└──────────────┬──────────────────────────────────────┘
               │
               ├──> Mock eMASS API (Flask)
               │    - Realistic POA&M data
               │    - Port 4010
               │
               └──> Splunk 9.2.1 (Docker)
                    - TA-securepro-eMASS installed
                    - Port 8000 (Web UI)
                    - Port 8089 (Management API)
```

### Mock eMASS API

Located in `demo/mock_emass_api.py`, provides:

- **Endpoint**: `http://localhost:4010/api/systems/55090/poams`
- **Sample Data**: 3 realistic POA&M records
  - POA-2024-001: High severity vulnerability (Ongoing)
  - POA-2024-002: Legacy authentication (Risk Accepted)
  - POA-2024-003: Missing SSL/TLS (Completed)
- **API Key**: `demo-api-key-12345`

### Demo Script

Located in `demo/create_demo_video.py`, performs:

1. Browser launch with video recording
2. Step-by-step automation:
   - Login
   - Navigate to configuration
   - Fill forms (with visible typing)
   - Create account and input
   - Search for data
   - Display results
3. Video export

## Customization

### Modify Demo Content

Edit `demo/mock_emass_api.py` to change:
- POA&M records
- System ID
- Number of records

### Adjust Recording Speed

Edit `demo/create_demo_video.py`:

```python
SLOW_MO = 1000  # Milliseconds to slow down each action
```

- `500` - Faster demo (~1-2 minutes)
- `1000` - Default (recommended)
- `2000` - Slower, more detailed demonstration

### Change Video Resolution

Edit `demo/create_demo_video.py`:

```python
viewport={"width": 1920, "height": 1080}
```

Common resolutions:
- 1280x720 (HD)
- 1920x1080 (Full HD) - default
- 2560x1440 (2K)

## Troubleshooting

### Splunk Not Starting

```bash
# Check logs
docker logs splunk-emass

# Restart
cd ..
docker-compose down -v
docker-compose up -d
```

### Mock API Not Responding

```bash
# Check if port is in use
lsof -i :4010

# Kill existing process
kill $(lsof -t -i:4010)

# Restart demo
./run_demo.sh
```

### Video File Not Created

- Ensure enough disk space (2GB+ free)
- Check `demo_output` directory exists
- Run in visible mode first to see errors
- Check Playwright installation: `playwright install chromium`

### Browser Automation Fails

```bash
# Reinstall Playwright browsers
source venv/bin/activate
playwright install --force chromium
```

### UI Elements Not Found

The Splunk UI may have changed. Edit `demo/create_demo_video.py` and update selectors:

```python
# Example: Update button selector
add_button_selectors = [
    'button:has-text("Add")',
    'button[label="Add"]',
    # Add more alternatives
]
```

## Technical Details

### Dependencies

**Python Packages** (`demo/requirements.txt`):
- `playwright==1.40.0` - Browser automation
- `flask==3.0.0` - Mock API server

**Browser**:
- Chromium (installed via Playwright)

### Network Configuration

Inside Docker:
- Splunk can reach mock API via `host.docker.internal:4010`
- Configured in account as base URL

From Host:
- Splunk UI: `http://localhost:8000`
- Mock API: `http://localhost:4010`

## CI/CD Integration

To run demo video creation in CI/CD:

```bash
# Headless mode, no interaction needed
./setup_demo.sh
cd ..
make build
cd demo
python create_demo_video.py --headless
```

Upload `demo_output/emass_demo.webm` as artifact.

## Best Practices

1. **First Run** - Use visible mode to verify everything works
2. **Consistent Environment** - Use Docker for reproducible demos
3. **Clean State** - Run `docker-compose down -v` between recordings
4. **Check Output** - Always verify video plays before presenting
5. **Backup** - Keep copy of successful video

## FAQ

**Q: Can I edit the video after creation?**
A: Yes! Use video editing software like:
- DaVinci Resolve (free)
- OpenShot (open source)
- Adobe Premiere Pro

**Q: How do I add narration?**
A: Record audio separately and combine using video editor or:
```bash
ffmpeg -i demo_output/emass_demo.webm -i narration.mp3 -c copy output.webm
```

**Q: Can I change the Splunk credentials?**
A: Yes, edit `docker-compose.yml` and `create_demo_video.py`:
- Update `SPLUNK_PASSWORD` in docker-compose.yml
- Update `SPLUNK_USERNAME` and `SPLUNK_PASSWORD` in create_demo_video.py

**Q: Will this work on Windows?**
A: Yes, with Windows Subsystem for Linux (WSL2). Install WSL2 and Docker Desktop.

**Q: How do I update the POA&M data shown?**
A: Edit `demo/mock_emass_api.py` and modify the `SAMPLE_POAMS` list.

## Support

For issues:
1. Check this README
2. Review logs: `docker logs splunk-emass`
3. Run in visible mode to see what's happening
4. Check GitHub issues: https://github.com/anthropics/claude-code/issues

## License

Same as parent project (TA-securepro-eMASS).

---

**Created with ❤️ using Playwright, Flask, and Docker**

No watermarks. No manual recording. Just professional demo videos.
