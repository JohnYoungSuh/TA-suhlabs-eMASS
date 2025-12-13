# Quick Start: Create Demo Video in 5 Minutes

This guide will help you create a professional demo video of TA-suhlabs-eMASS without any watermarks.

## Step 1: Setup (One-time, ~2 minutes)

```bash
cd demo
./setup_demo.sh
```

Wait for it to complete. This installs all dependencies.

## Step 2: Build Add-on (~30 seconds)

```bash
cd ..
make build
cd demo
```

## Step 3: Create Video (~2-3 minutes)

```bash
./run_demo.sh
```

Choose recording mode:
- **Option 1**: Visible mode (watch it happen) - recommended for first time
- **Option 2**: Headless mode (background) - faster

Wait for completion...

## Step 4: Get Your Video

Your video is ready at: **`demo/demo_output/emass_demo.webm`**

### Optional: Convert to MP4 (for PowerPoint)

```bash
./convert_to_mp4.sh
```

This creates `demo_output/emass_demo.mp4` for better compatibility.

## That's It!

Show the video to your manager. No watermarks, professional quality.

## What If Something Goes Wrong?

### "Splunk not starting"
```bash
docker logs splunk-emass
# Wait a bit longer, Splunk takes 2-3 minutes to fully start
```

### "Mock API not responding"
```bash
# Kill any existing process on port 4010
kill $(lsof -t -i:4010)
# Run demo again
./run_demo.sh
```

### "Video file not created"
- Run in visible mode (option 1) to see what's happening
- Check you have 2GB+ free disk space
- Make sure Docker is running

## Need Help?

See the full [README.md](README.md) for detailed documentation.

---

**Total time from zero to video: ~5 minutes**
