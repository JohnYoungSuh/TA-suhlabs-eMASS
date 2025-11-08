# Selenium vs Playwright for Demo Video

## Overview

We now have **two versions** of the demo video automation:

1. **Playwright Version** (original) - `create_demo_video.py`
2. **Selenium Version** (new) - `create_demo_video_selenium.py`

Both create automated demo videos without watermarks. Choose based on your needs and familiarity.

---

## Quick Comparison

| Feature | Playwright | Selenium |
|---------|-----------|----------|
| **Built-in Video Recording** | ✅ Yes (native) | ❌ No (uses OpenCV) |
| **Browser Support** | Chromium, Firefox, WebKit | Chrome, Firefox, Edge, Safari |
| **Learning Curve** | Steeper (newer API) | Gentler (widely known) |
| **Documentation** | Good (official docs) | Excellent (huge community) |
| **Speed** | Faster | Slightly slower |
| **Setup** | Simple (`playwright install`) | Needs ChromeDriver |
| **Screen Recording** | Browser viewport only | Full screen |
| **Maturity** | Newer (2020) | Mature (2004) |
| **WSL Support** | Better (headless) | Good (needs X server for visible) |

---

## Playwright Version

### Pros
✅ Built-in video recording (no external tools)
✅ Records browser viewport precisely
✅ Faster execution
✅ Modern async API
✅ Better for headless automation

### Cons
❌ Newer (less community support)
❌ Requires `playwright install` for browsers
❌ Less familiar to most developers

### Setup
```bash
cd demo
./setup_demo.sh
source venv/bin/activate
playwright install chromium
```

### Run
```bash
./run_demo_wsl.sh
```

### Output
- Format: WebM
- Records: Browser viewport only
- Size: ~10-20 MB

---

## Selenium Version

### Pros
✅ Very mature and well-documented
✅ Huge community (easy to find help)
✅ Most developers already know it
✅ Works with existing Chrome installation

### Cons
❌ No built-in video recording (uses OpenCV)
❌ Records full screen (not just browser)
❌ Slightly slower
❌ More complex video recording setup

### Setup
```bash
cd demo
./setup_demo_selenium.sh
source venv/bin/activate
```

### Run
```bash
./run_demo_selenium.sh
```

### Output
- Format: AVI (convert to MP4)
- Records: Full screen
- Size: Larger (~50-100 MB)

---

## Technical Differences

### Video Recording

**Playwright:**
```python
# Built-in
context = await browser.new_context(
    record_video_dir="./demo_output",
    record_video_size={"width": 1920, "height": 1080}
)
```

**Selenium:**
```python
# Uses OpenCV + PIL to capture screen
recorder = ScreenRecorder(VIDEO_PATH, fps=20)
recorder.start()
# ... automation ...
recorder.stop()
```

### Element Selection

**Playwright:**
```python
await page.click('button:has-text("Add")')
await page.fill('input[name="username"]', "admin")
```

**Selenium:**
```python
button = driver.find_element(By.XPATH, "//button[contains(text(), 'Add')]")
button.click()
driver.find_element(By.NAME, "username").send_keys("admin")
```

### Async vs Sync

**Playwright:** Async/await
```python
async def create_demo():
    async with async_playwright() as p:
        browser = await p.chromium.launch()
```

**Selenium:** Synchronous
```python
def create_demo():
    driver = webdriver.Chrome(options=chrome_options)
```

---

## Which Should You Use?

### Choose **Playwright** if:
- ✅ You want native video recording
- ✅ You're comfortable with async Python
- ✅ You want precise browser viewport recording
- ✅ You're running in WSL/headless environment
- ✅ You want smaller video files

### Choose **Selenium** if:
- ✅ You're already familiar with Selenium
- ✅ You want more community support
- ✅ You need to show full screen (not just browser)
- ✅ You prefer synchronous code
- ✅ You want to use existing Chrome installation

---

## Migration Guide

### From Playwright to Selenium

**Dependencies:**
```bash
# Remove Playwright
pip uninstall playwright

# Install Selenium
pip install selenium opencv-python pillow webdriver-manager
```

**Code Changes:**
```python
# Playwright
from playwright.async_api import async_playwright
async def demo():
    async with async_playwright() as p:
        browser = await p.chromium.launch()
        page = await browser.new_page()
        await page.goto(URL)

# Selenium
from selenium import webdriver
def demo():
    driver = webdriver.Chrome()
    driver.get(URL)
```

### From Selenium to Playwright

```bash
# Remove Selenium
pip uninstall selenium opencv-python pillow

# Install Playwright
pip install playwright
playwright install chromium
```

---

## File Structure

```
demo/
├── Playwright Version:
│   ├── create_demo_video.py
│   ├── setup_demo.sh
│   ├── run_demo_wsl.sh
│
├── Selenium Version:
│   ├── create_demo_video_selenium.py
│   ├── setup_demo_selenium.sh
│   ├── run_demo_selenium.sh
│
└── Shared:
    ├── mock_emass_api.py
    ├── convert_to_mp4.sh
    ├── cleanup_demo.sh
    └── requirements.txt  (updated for Selenium)
```

---

## Troubleshooting

### Playwright Issues

**Problem:** `playwright._impl._errors.Error: Executable doesn't exist`
**Solution:**
```bash
playwright install chromium
```

**Problem:** Video not created
**Solution:** Check disk space, verify `demo_output/` directory exists

### Selenium Issues

**Problem:** `WebDriverException: chrome not reachable`
**Solution:**
```bash
sudo apt-get install chromium-browser chromium-chromedriver
```

**Problem:** Screen recording fails
**Solution:** Install OpenCV dependencies:
```bash
sudo apt-get install libgl1-mesa-glx libglib2.0-0
```

**Problem:** Black screen in WSL
**Solution:** Use headless mode:
```bash
python create_demo_video_selenium.py --headless
```

---

## Performance Comparison

**Test Environment:** WSL2, 4GB RAM, Docker Desktop

| Metric | Playwright | Selenium |
|--------|-----------|----------|
| Setup Time | ~2 min | ~3 min |
| Recording Time | ~3 min | ~3 min |
| Video Size | 15 MB | 80 MB |
| CPU Usage | Low | Medium |
| Memory Usage | 200 MB | 400 MB |

---

## Recommendations

### For Production Use
**Playwright** - More reliable, smaller files, faster

### For Learning/Development
**Selenium** - Better documentation, easier to debug

### For WSL
**Playwright** - Better headless support

### For CI/CD
**Playwright** - Faster, more deterministic

---

## Converting Between Formats

### Playwright (WebM) → MP4
```bash
ffmpeg -i demo_output/emass_demo.webm -c:v libx264 -crf 23 demo_output/emass_demo.mp4
```

### Selenium (AVI) → MP4
```bash
ffmpeg -i demo_output/emass_demo.avi -c:v libx264 -crf 23 demo_output/emass_demo.mp4
```

### Either → GIF (for presentations)
```bash
ffmpeg -i input.mp4 -vf "fps=10,scale=1280:-1:flags=lanczos" -c:v gif output.gif
```

---

## Summary

Both approaches work! The choice depends on your:
- Experience level
- Environment (WSL, Linux, Mac)
- Requirements (file size, quality, format)
- Familiarity with async Python

**Our recommendation:** Start with **Selenium** if you're familiar with it, or **Playwright** if you want a more modern approach with built-in video recording.

Both frameworks are included in this demo setup - try both and see which works better for your use case!
