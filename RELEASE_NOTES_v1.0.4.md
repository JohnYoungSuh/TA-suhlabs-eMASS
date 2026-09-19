# Release Notes — TA-suhlabs-eMASS v1.0.4

**Release Date:** 2026-05-21
**Branch:** main

---

## Summary

Maintenance release focused on build tooling hardening, configuration correctness, and developer experience improvements.

---

## Changes

### 🔧 Build & Makefile

- **`make validate` permission fix** — `validate` target now auto-repairs root-owned `output/` files before running checks, preventing `Permission denied` errors caused by Docker volume mounts writing files as root.
- **`make zip` now depends on `validate`** *(pending)* — Ensures the package is always validated before zipping for Splunkbase upload.

### ⚙️ globalConfig.json

- **`loggingTab` schema fix** — Added missing `name` and `title` fields to the `loggingTab` entry in the Configuration tabs. The previous definition used `"label"` which is not a valid UCC field for tab definitions. This caused inconsistent rendering in some UCC versions.
  ```json
  // Before (incorrect)
  { "type": "loggingTab", "label": "Log Level" }

  // After (correct)
  { "name": "logging", "title": "Logging", "type": "loggingTab" }
  ```

### 📋 Inputs UI

- Confirmed `inputs` page is correctly defined in `globalConfig.json` with the `emass_poam` service, including fields: `name`, `account`, `interval`, `index`.
- Verified 22 UI JS files present in `appserver/static/js/build/` — Inputs tab renders correctly at `/en-US/app/TA-suhlabs-eMASS/inputs`.

---

## Known Issues

- `venv/` directory is tracked by Git despite being listed in `.gitignore` (was committed before ignore rule was added). Run `git rm -r --cached venv/` to untrack if needed.

---

## Upgrade Notes

- No schema migrations required.
- No `inputs.conf` changes — existing input instances are unaffected.
- Rebuild recommended: `make build && docker compose restart`

---

## Verified On

- Splunk Enterprise: 10.4.0
- UCC Framework: 6.1.0
- Python: 3.12 / 3.13
- Docker: splunk/splunk:latest
