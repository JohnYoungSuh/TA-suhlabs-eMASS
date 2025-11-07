# Demo Cleanup Guide

This guide helps you remove demo files and reverse changes made to your WSL environment.

## Quick Reference

| What to Remove | Script to Run | What It Does |
|----------------|---------------|--------------|
| Just runtime files | `./cleanup_demo.sh` | Removes venv, output, cache (keeps source) |
| Everything | `./cleanup_complete.sh` | Removes entire demo/ directory |
| System packages | `./cleanup_system_packages.sh` | Removes apt packages (optional) |

## Option 1: Clean Runtime Files Only (Recommended)

**Removes:** Virtual environment, output files, caches
**Keeps:** Demo scripts and documentation

```bash
cd /home/suhlabs/projects/securepro/TA-securepro-eMASS/demo
./cleanup_demo.sh
```

This removes:
- `venv/` directory
- `demo_output/` directory
- `~/.cache/ms-playwright/` (browser cache)
- Python `__pycache__` files
- Running Mock API processes
- Docker containers

**After this**, you can still run the demo again by running `./setup_demo.sh`.

---

## Option 2: Remove Demo Directory Completely

**Removes:** Everything in the demo/ directory

```bash
cd /home/suhlabs/projects/securepro/TA-securepro-eMASS
./demo/cleanup_complete.sh
```

This removes:
- All demo scripts (`.py`, `.sh`)
- All documentation (`.md` files)
- Virtual environment
- Output files
- The entire `demo/` directory

**After this**, the demo is completely gone. To get it back, you'd need to `git checkout` the branch again.

---

## Option 3: Remove System Packages (Usually Not Needed)

**Removes:** System libraries installed via apt-get

```bash
cd /home/suhlabs/projects/securepro/TA-securepro-eMASS/demo
./cleanup_system_packages.sh
```

This removes packages like:
- `libnss3`, `libnspr4`, `libasound2`
- X11 and graphics libraries
- Audio libraries

**Warning:**
- Only do this if you're sure you don't need these libraries
- Other applications might use these packages
- apt will only remove them if nothing else depends on them
- Usually it's fine to leave these installed

---

## Manual Cleanup (Step-by-Step)

If you prefer to do it manually:

### 1. Stop Running Services

```bash
# Stop Mock API
pkill -f "mock_emass_api.py"

# Stop Docker containers
cd /home/suhlabs/projects/securepro/TA-securepro-eMASS
docker compose down -v
```

### 2. Remove Virtual Environment

```bash
cd /home/suhlabs/projects/securepro/TA-securepro-eMASS/demo
rm -rf venv/
```

### 3. Remove Output Files

```bash
rm -rf demo_output/
```

### 4. Remove Playwright Cache

```bash
rm -rf ~/.cache/ms-playwright/
```

### 5. Remove Python Cache

```bash
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null
find . -type f -name "*.pyc" -delete 2>/dev/null
```

### 6. Remove Demo Directory (Optional)

```bash
cd /home/suhlabs/projects/securepro/TA-securepro-eMASS
rm -rf demo/
```

### 7. Remove System Packages (Optional)

```bash
sudo apt-get autoremove -y libnss3 libnspr4 libasound2
```

---

## What About Git?

The demo files are in your Git repository. Even after removing files locally, they're still in Git history.

### To Remove from Git (Delete from Branch)

```bash
cd /home/suhlabs/projects/securepro/TA-securepro-eMASS

# Remove demo directory from Git
git rm -rf demo/
git commit -m "Remove demo directory"
git push
```

### To Keep in Git But Clean Locally

Just run the cleanup scripts. The files stay in the repository but are removed from your working directory.

You can restore them anytime with:
```bash
git checkout demo/
```

---

## Recommended Cleanup Workflow

For most users, we recommend:

```bash
# 1. Clean runtime files (safe, reversible)
cd /home/suhlabs/projects/securepro/TA-securepro-eMASS/demo
./cleanup_demo.sh

# 2. If you never want the demo again
./cleanup_complete.sh

# 3. System packages - only if you're sure
# (Usually NOT recommended - just leave them)
# ./cleanup_system_packages.sh
```

---

## Troubleshooting

### "Permission denied" errors

Some files might be owned by root (from Docker). Fix with:
```bash
sudo chown -R $USER:$USER /home/suhlabs/projects/securepro/TA-securepro-eMASS/demo
```

### Docker containers won't stop

```bash
docker ps -a | grep emass
docker rm -f <container-id>
```

### Mock API process won't stop

```bash
ps aux | grep mock_emass_api
kill -9 <pid>
```

### Want to start fresh after cleanup

```bash
cd /home/suhlabs/projects/securepro/TA-securepro-eMASS
git checkout demo/
cd demo
./setup_demo.sh
```

---

## What Gets Left Behind

Even after complete cleanup, these remain:
- Docker Desktop (on Windows)
- System packages if other apps use them
- Git repository files (unless explicitly removed from Git)
- Python 3 installation
- Docker installation

These are all safe to leave - they don't take much space and might be useful for other projects.

---

## Quick Commands Reference

```bash
# Light cleanup (recommended)
./cleanup_demo.sh

# Complete removal
./cleanup_complete.sh

# Remove system packages (optional)
./cleanup_system_packages.sh

# Manual nuclear option
cd /home/suhlabs/projects/securepro/TA-securepro-eMASS
docker compose down -v
pkill -f "mock_emass_api.py"
rm -rf demo/
rm -rf ~/.cache/ms-playwright/
```

---

That's it! Choose the cleanup level that makes sense for you.
