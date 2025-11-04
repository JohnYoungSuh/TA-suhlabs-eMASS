# TA-securepro-eMASS Build Fix Summary

**Date:** 2025-11-01
**UCC Version:** 6.0.1
**Status:** ✅ All issues resolved

---

## Critical Issues Fixed

### 1. Virtual Environment Location (ROOT CAUSE)
**Problem:**
- venv was created in `package/.venv/` (WRONG)
- UCC documentation requires venv at project root

**Solution:**
- Deleted `package/.venv/`
- Created `.venv/` at project root
- Updated Makefile `VENV := .venv` (line 8)

**Verification:**
```bash
ls -la .venv/                    # ✅ Exists at root
ls -la package/.venv/            # ✅ Does not exist
```

---

### 2. UCC 6.0.1 UI Bundle Bug
**Problem:**
- UCC 6.0.1 has packaging bug where JavaScript UI files aren't copied to output
- Only `globalConfig.json` was generated in `appserver/static/js/build/`
- Missing 22 JavaScript bundle files needed for Splunk Web UI

**Root Cause:**
UCC changelog claims v6.0.1 fixes "include built UI files in the wheel package" but `ucc-gen build` still doesn't copy them from the package to output directory.

**Solution:**
Created workaround script `fix_ui.sh`:
```bash
#!/bin/bash
# Copies pre-built UI files from UCC package to output
cp -r .venv/lib/python3.12/site-packages/splunk_add_on_ucc_framework/package/appserver \
      output/TA-securepro-eMASS/
```

**Makefile Integration:**
Added `@./fix_ui.sh` to build target (line 42)

**Verification:**
```bash
find output/TA-securepro-eMASS/appserver -name "*.js" | wc -l
# Expected: 22 JavaScript files
```

---

### 3. Invalid Keys in restmap.conf
**Problem:**
VSCode showing "invalid key in stanza" errors:
- Line 7: `handlertype = python` (INVALID)
- Line 14: `handlertype = python` (INVALID)

**Solution:**
Cleaned up `package/default/restmap.conf`:
- Removed invalid `handlertype` keys
- Removed invalid `handlerpersistentmode` keys
- Fixed typo in stanza name
- Deleted duplicate file in root `/default/` directory

**Final Valid Configuration:**
```conf
[admin:TA_securepro_eMASS]
match = /
members = ta_securepro_emass_account

[admin_external:ta_securepro_emass_account]
handlerfile = ta_securepro_emass_rh_account.py
handleractions = edit, list, remove, create
```

---

### 4. Configuration Architecture Change
**Problem:**
Simple input-only configuration pattern

**Solution:**
Migrated to Salesforce-style account-based pattern:

**Account Configuration** (`globalConfig.json` → configuration.tabs.account):
- Stores reusable credentials: `system_id`, `base_url`, `api_key` (encrypted), `name`
- Supports multiple eMASS instances

**Input Configuration** (`globalConfig.json` → inputs.services.emass_poam):
- References account by name via `referenceName: "account"`
- Configures collection: `interval`, `index`

**REST Handler:**
Created `package/bin/ta_securepro_emass_rh_account.py` using `MultipleModel` pattern for account CRUD operations.

---

## Files Created

### 1. `fix_ui.sh` (NEW)
- **Purpose:** Workaround for UCC 6.0.1 UI packaging bug
- **Location:** Project root
- **Permissions:** Executable (`chmod +x`)
- **Called by:** Makefile build target

### 2. `package/bin/ta_securepro_emass_rh_account.py` (NEW)
- **Purpose:** REST handler for account management
- **Pattern:** MultipleModel (supports multiple account instances)
- **Fields:** system_id (Pattern validation), base_url (String), api_key (Encrypted)

### 3. `package/bin/import_declare_test.py` (NEW)
- **Purpose:** Python path setup for lib/ imports
- **Required by:** All REST handlers

### 4. `package/app.manifest` (NEW)
- **Purpose:** Required by UCC 6.0.1
- **Schema:** 2.0.0
- **Content:** App metadata (title, version, description)

### 5. `package/lib/requirements.txt` (NEW)
- **Purpose:** Runtime dependencies installed to output/lib/
- **Content:**
  ```
  solnlib>=1.2.0
  splunktaucclib>=6.0.0
  ```

### 6. `.vscode/settings.json` (NEW)
- **Purpose:** VSCode Python import resolution
- **Paths:** bin/, lib/, package/bin/, package/lib/, output/lib/

---

## Files Modified

### 1. `Makefile`
**Changes:**
- Line 8: `VENV := .venv` (was `$(PKG_DIR)/.venv`)
- Line 24: `@$(PYTHON) -m venv .venv` (was `cd $(PKG_DIR) && ...`)
- Line 26: `requirements.txt` (was `../requirements.txt`)
- Line 42: Added `@./fix_ui.sh` after ucc-gen build
- Line 77: `@rm -rf $(OUT_DIR) .venv` (was `$(PKG_DIR)/.venv`)

### 2. `package/globalConfig.json`
**Changes:**
- Added `configuration.tabs[0]` → account configuration page
- Modified `inputs.services[0].entity` → added account reference field
- Account fields: name, system_id, base_url, api_key (encrypted)
- Input references account via `referenceName: "account"`

### 3. `package/default/restmap.conf`
**Changes:**
- Removed invalid `handlertype = python` keys
- Removed invalid `handlerpersistentmode = true` keys
- Fixed stanza name typo
- Simplified to only valid Splunk restmap keys

---

## Files Deleted

### 1. `package/.venv/` (DELETED)
- **Reason:** Wrong location per UCC documentation

### 2. `/default/restmap.conf` (root directory - DELETED)
- **Reason:** Duplicate file with typos, wrong location

### 3. Entire `/default/` directory in root (DELETED)
- **Reason:** Configuration should only be in `package/default/`

### 4. `package/bin/ta_securepro_emass_rh_settings.py` (DELETED)
- **Reason:** Old REST handler from previous architecture

### 5. `package/bin/ta_securepro_emass_rh_emass_poam_input.py` (DELETED)
- **Reason:** Old REST handler from previous architecture

### 6. `package/default/app.conf` (DELETED)
- **Reason:** UCC auto-generates this file

### 7. `globalConfig.json` in root (DELETED multiple times)
- **Reason:** UCC keeps recreating it; only `package/globalConfig.json` should exist
- **Note:** UCC may recreate this during build - harmless but can be deleted

---

## Build Process Verification

### Current Working Build
```bash
# 1. Setup (if needed)
make setup

# 2. Build
make build
```

**Build Steps:**
1. Lint: Validates `package/globalConfig.json`
2. Clean: Removes old `output/`
3. UCC Build: `ucc-gen build --source package --ta-version 1.0.0`
4. **UI Fix:** `./fix_ui.sh` copies UI bundle files
5. Validation: Checks for recursive output directories

### Output Structure Verification
```bash
output/TA-securepro-eMASS/
├── appserver/
│   └── static/
│       └── js/
│           └── build/
│               ├── *.js (22 files)          ✅ Fixed by fix_ui.sh
│               └── globalConfig.json        ✅ Always generated
├── bin/
│   ├── ta_securepro_emass_rh_account.py    ✅ Account REST handler
│   └── import_declare_test.py              ✅ Path setup
├── default/
│   ├── app.conf                             ✅ UCC auto-generated
│   ├── restmap.conf                         ✅ Copied from package
│   └── inputs.conf.spec                     ✅ UCC auto-generated
└── lib/
    └── splunktaucclib/                      ✅ v8.0.0 installed
```

---

## Known Issues & Workarounds

### Issue 1: UCC 6.0.1 UI Bug
**Status:** WORKAROUND IN PLACE
**Impact:** Without workaround, Configuration page won't render in Splunk Web
**Workaround:** `fix_ui.sh` script (automated in Makefile)
**Permanent Fix:** Wait for UCC v6.0.2 or later

### Issue 2: Root globalConfig.json Regeneration
**Status:** COSMETIC ISSUE
**Impact:** UCC recreates `globalConfig.json` in root during build
**Workaround:** Safe to delete; doesn't affect build
**Permanent Fix:** UCC behavior (not configurable)

---

## Testing Checklist

- [x] venv created at project root (`.venv/`)
- [x] No venv in `package/` directory
- [x] UCC build succeeds without errors
- [x] 22 JavaScript UI files present in output
- [x] `fix_ui.sh` executes successfully
- [x] restmap.conf has no invalid keys
- [x] VSCode shows no validation errors
- [x] splunktaucclib v8.0.0 installed to output/lib/
- [x] Account REST handler present in output
- [x] app.manifest created and valid
- [x] Makefile `make build` works end-to-end

---

## Next Steps

### 1. Deploy to Splunk
```bash
# Copy to Splunk apps directory
cp -r output/TA-securepro-eMASS $SPLUNK_HOME/etc/apps/

# Restart Splunk
$SPLUNK_HOME/bin/splunk restart
```

### 2. Configure in Splunk Web
1. Navigate to: Apps → TA-securepro-eMASS → Configuration
2. Add Account:
   - Account Name: `emass_prod`
   - System ID: `55090`
   - Base URL: `http://localhost:4010`
   - API Key: `<your-key>`
3. Add Input:
   - Input Name: `emass_poam_collection`
   - Account: Select `emass_prod`
   - Interval: `3600`
   - Index: `mnhrs_emass_poc`

### 3. Verify Data Collection
```spl
index=mnhrs_emass_poc sourcetype="emass:poam"
| stats count by sourcetype
```

---

## References

- **UCC Documentation:** https://splunk.github.io/addonfactory-ucc-generator/
- **UCC Changelog:** https://splunk.github.io/addonfactory-ucc-generator/CHANGELOG/
- **Issue: UCC 6.0.1 UI Bug:** Version 6.0.1 (2025-09-30) - "include built UI files in the wheel package"

---

## Contributors

- Initial venv location discovery and fix
- UCC 6.0.1 UI bug identification and workaround
- Account-based architecture implementation
- restmap.conf validation and cleanup

---

**Last Updated:** 2025-11-01
**Build Status:** ✅ WORKING
**Deployment Status:** Ready for Splunk installation
