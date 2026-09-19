# Release Notes: TA-suhlabs-eMASS v1.0.5

**Release Date:** 2026-05-21
**UCC Framework Version:** 6.1.0

## Overview
Version 1.0.5 is a quality and packaging release that resolves AppInspect validation failures, introduces a proper application icon, and hardens the build and packaging pipeline against runtime side effects caused by Docker volume mounts.

## New Features
- **Application Icon**: Added proper `appIcon.png` (36x36) and `appIcon_2x.png` (72x72) to `package/appserver/static/`. Icons are valid PNG files resized to Splunk-required dimensions using Pillow.

## Bug Fixes
- **AppInspect: Nested app.conf**: Splunk was writing `default.old.TIMESTAMP/` backup directories into the volume-mounted `output/` directory during container upgrades. These directories were being packaged into the `.tar.gz`, causing AppInspect to reject the package with a "nested app.conf" error. Fixed by excluding `default.old.*` in `zip_ta.sh` and auto-removing them during `make validate`.
- **AppInspect: Invalid PNG**: Previous icon files were copied directly from the image generator without proper resizing, resulting in files that failed PNG validation. Fixed by using PIL/Pillow to produce correctly-sized, valid PNG files.
- **globalConfig.json: loggingTab schema**: The `loggingTab` entry was missing the required `name` and `title` fields (was using `label` instead). Corrected to match UCC schema standards.

## Build & Tooling
- **make validate — Permission Fix**: The `validate` target now auto-repairs root-owned `output/` files before running checks. Docker volume mounts can cause files to be owned by root, previously causing `Permission denied` errors on `grep` checks.
- **make validate — Stale Backup Cleanup**: `validate` now automatically removes `default.old.*` directories before validation and packaging, preventing AppInspect failures.
- **zip_ta.sh — Exclusion Hardening**: Added `--exclude "TA-suhlabs-eMASS/default.old.*"` to the tar command as a safety net even if cleanup is bypassed.

## Upgrade Notes
- No schema migrations required.
- No `inputs.conf` changes — existing input instances are unaffected.
- Rebuild and repackage required: `make build && make zip`

## Verified On
- Splunk Enterprise: 10.4.0
- UCC Framework: 6.1.0
- Python: 3.12 / 3.13
- Docker: splunk/splunk:latest

---

*Note: v1.0.4 was not released. The version was incremented to 1.0.5 to clear an AppInspect "previously used version" rejection.*
