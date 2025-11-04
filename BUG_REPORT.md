# Bug Report: UI Bundle Files Not Copied to Output in v6.0.1

## Title
**Bug: `ucc-gen build` does not copy UI JavaScript bundle files to output directory in v6.0.1**

---

## Description

Despite the v6.0.1 changelog claiming to fix "include built UI files in the wheel package," the `ucc-gen build` command only copies `globalConfig.json` to the output directory but fails to copy the 22 JavaScript bundle files required for the Configuration and Inputs pages to render in Splunk Web.

### What Should Happen
When running `ucc-gen build --source package --ta-version 1.0.0`, all UI files should be copied from the UCC framework package to the output directory:

```
output/TA-<addon-name>/appserver/static/js/build/
├── ConfigurationPage.*.js
├── Dashboard.*.js
├── entry_page.js
├── globalConfig.json
└── ... (22 total JavaScript files)
```

### What Actually Happens
Only `globalConfig.json` is created in the output directory:

```
output/TA-<addon-name>/appserver/static/js/build/
└── globalConfig.json
```

All 22 JavaScript bundle files are missing, causing the Configuration and Inputs pages to fail to load in Splunk Web.

---

## UCC Version

**Version:** 6.0.1

```bash
$ pip show splunk-add-on-ucc-framework
Name: splunk-add-on-ucc-framework
Version: 6.0.1
Summary:
Home-page:
Author: Splunk
Author-email: addonfactory@splunk.com
License: Apache-2.0
Location: /path/to/.venv/lib/python3.12/site-packages
Requires: PyYAML, addonfactory-splunk-conf-parser-lib, certifi, colorama, defusedxml, dunamai, jinja2, jsonschema, packaging
Required-by:
```

---

## Additional System Info

- **Operating System:** Linux 6.6.87.2-microsoft-standard-WSL2 (WSL2 on Windows)
- **Python Version:** 3.12.3
- **Installation Method:** `pip install splunk-add-on-ucc-framework==6.0.1`
- **Virtual Environment:** Python venv at project root (`.venv/`)
- **Build Command:** `ucc-gen build --source package --ta-version 1.0.0`

---

## Steps to Reproduce

### 1. Create minimal UCC project structure

```bash
mkdir test-ucc-bug && cd test-ucc-bug

mkdir -p package/bin
mkdir -p package/default
mkdir -p package/lib
```

### 2. Create minimal `package/globalConfig.json`

```json
{
  "meta": {
    "name": "TA-test-addon",
    "restRoot": "ta_test_addon",
    "displayName": "Test Addon",
    "version": "1.0.0",
    "schemaVersion": "0.0.9"
  },
  "pages": {
    "configuration": {
      "title": "Configuration",
      "tabs": [
        {
          "name": "account",
          "title": "Account",
          "entity": [
            {
              "field": "name",
              "label": "Account Name",
              "type": "text",
              "required": true
            }
          ]
        }
      ]
    },
    "inputs": {
      "title": "Inputs",
      "services": [
        {
          "name": "test_input",
          "title": "Test Input",
          "entity": [
            {
              "field": "name",
              "label": "Input Name",
              "type": "text",
              "required": true
            },
            {
              "field": "interval",
              "label": "Interval",
              "type": "text",
              "required": true,
              "defaultValue": "300"
            }
          ]
        }
      ]
    }
  }
}
```

### 3. Create `package/app.manifest`

```json
{
  "schemaVersion": "2.0.0",
  "info": {
    "title": "Test Addon",
    "id": {
      "group": null,
      "name": "TA-test-addon",
      "version": "1.0.0"
    },
    "author": [{"name": "Test", "email": null, "company": null}],
    "releaseDate": null,
    "description": "Test addon for UCC bug reproduction",
    "classification": {
      "intendedAudience": null,
      "categories": [],
      "developmentStatus": null
    },
    "commonInformationModels": null,
    "license": {"name": null, "text": null, "uri": null},
    "privacyPolicy": {"name": null, "text": null, "uri": null},
    "releaseNotes": {"name": null, "text": null, "uri": null}
  },
  "dependencies": null,
  "tasks": null,
  "inputGroups": null,
  "incompatibleApps": null,
  "platformRequirements": null,
  "supportedDeployments": ["*"],
  "targetWorkloads": ["*"]
}
```

### 4. Setup virtual environment and install UCC

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install splunk-add-on-ucc-framework==6.0.1
```

### 5. Run build

```bash
ucc-gen build --source package --ta-version 1.0.0
```

### 6. Verify bug

```bash
# Check what files were generated
find output/TA-test-addon/appserver/static/js/build -type f

# Expected output (SHOULD include 22+ files):
# output/TA-test-addon/appserver/static/js/build/ConfigurationPage.*.js
# output/TA-test-addon/appserver/static/js/build/Dashboard.*.js
# output/TA-test-addon/appserver/static/js/build/entry_page.js
# ... etc

# Actual output (BUG - only 1 file):
# output/TA-test-addon/appserver/static/js/build/globalConfig.json
```

### 7. Verify UI files exist in UCC package

```bash
# The files ARE in the installed package:
find .venv/lib/python3.*/site-packages/splunk_add_on_ucc_framework/package/appserver/static/js/build -name "*.js" | wc -l

# Output: 22 (files exist in package but aren't copied)
```

---

## Expected Behavior

When running `ucc-gen build`, the build process should:

1. Copy all JavaScript bundle files from the UCC framework package
2. Place them in `output/<addon-name>/appserver/static/js/build/`
3. Result in a fully functional UI when the add-on is installed in Splunk

**Expected file count in output:**
- 22 JavaScript files (`.js`)
- 1 globalConfig.json
- **Total: 23 files** in `appserver/static/js/build/`

---

## Actual Behavior

`ucc-gen build` only copies `globalConfig.json` and skips all JavaScript bundle files.

**Actual file count in output:**
- 0 JavaScript files (`.js`)
- 1 globalConfig.json
- **Total: 1 file** in `appserver/static/js/build/`

**Result:** Configuration and Inputs pages fail to load in Splunk Web with console errors about missing JavaScript modules.

---

## Verification That Files Exist in Package

The UI files ARE present in the installed wheel package:

```bash
$ ls .venv/lib/python3.12/site-packages/splunk_add_on_ucc_framework/package/appserver/static/js/build/

ArrowBroadUnderbarDown.wq6id2ca.js
ConfigurationPage.BMWcI2qM.js
Dashboard.Custom.4DCm98Q1.js
Dashboard.DashboardPage.DIXsiGU0.js
Dashboard.DataIngestion.zTYz9PSE.js
Dashboard.EnterpriseViewOnlyPreset.hOZR46Qg.js
Dashboard.Error.W5Ap4UPE.js
Dashboard.Overview.Cw6waP2U.js
Dashboard.Resource.bqf5JefA.js
Dashboard.utils.0p-tEVNs.js
ErrorBoundary.xJor3Ppq.js
Search.BNBTqs0I.js
entry_page.js
globalConfig.json
index.es.CnGmB-1e.js
index.es.D0O8L3dD.js
purify.es.CQJ0hv7W.js
usePlatform.CFP4tBzQ.js
... (22 total .js files)
```

This confirms the v6.0.1 changelog fix "include built UI files in the wheel package" - the files ARE in the package, but `ucc-gen build` doesn't copy them to the output directory.

---

## Impact

**Severity:** High

- **Configuration UI broken:** Users cannot configure the add-on via Splunk Web
- **Inputs UI broken:** Users cannot create/edit inputs via Splunk Web
- **Affects all UCC 6.0.1 users:** Anyone building add-ons with v6.0.1 experiences this
- **Silent failure:** Build succeeds without errors, but UI doesn't work when deployed

---

## Workaround

Manual copy after build:

```bash
# After running ucc-gen build
cp -r .venv/lib/python3.12/site-packages/splunk_add_on_ucc_framework/package/appserver \
      output/TA-<addon-name>/

# Verify fix
find output/TA-<addon-name>/appserver/static/js/build -name "*.js" | wc -l
# Should output: 22
```

**Automated workaround script:**

```bash
#!/bin/bash
# fix_ui.sh - Workaround for UCC 6.0.1 UI bug

UCC_UI_SOURCE=".venv/lib/python3.12/site-packages/splunk_add_on_ucc_framework/package/appserver"
OUTPUT_DIR="output/TA-<addon-name>"

if [ ! -d "$UCC_UI_SOURCE" ]; then
    echo "ERROR: UCC UI source not found at $UCC_UI_SOURCE"
    exit 1
fi

if [ ! -d "$OUTPUT_DIR" ]; then
    echo "ERROR: Output directory not found. Run 'ucc-gen build' first."
    exit 1
fi

cp -r "$UCC_UI_SOURCE" "$OUTPUT_DIR/"
echo "✓ Copied UI files successfully"
```

---

## Possible Root Cause

The v6.0.1 changelog mentions fixing "include built UI files in the wheel package" which successfully added the files to the package, but it appears the `ucc-gen build` command's file copy logic was not updated to copy these files from the package to the output directory.

Likely location of issue: Build command only copies `globalConfig.json` but doesn't have logic to copy the pre-built JavaScript bundle files from `splunk_add_on_ucc_framework/package/appserver/` to `output/<addon>/appserver/`.

---

## Related Information

- **Changelog:** https://splunk.github.io/addonfactory-ucc-generator/CHANGELOG/
- **Version 6.0.1 (2025-09-30):** Bug fix: "include built UI files in the wheel package"
- **Version 6.0.0 (2025-09-26):** Trigger UCC 6 release

The bug appears to be an incomplete fix from v6.0.1 - files are now in the package but the build command doesn't use them.

---

## Request

Please update `ucc-gen build` to copy all files from `splunk_add_on_ucc_framework/package/appserver/` to the output directory, not just `globalConfig.json`.

Thank you for maintaining this framework!
