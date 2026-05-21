#!/bin/bash
# Workaround for UCC 6.0.1 bug where UI files aren't copied to output
#
# Bug: UCC 6.0.1 claims to fix "include built UI files in the wheel package"
# but the build command still doesn't copy them from the package to output.
#
# This script manually copies the pre-built UI files from the UCC package
# to the output directory after running ucc-gen build.

set -e

echo "Copying UCC UI files to output..."

UCC_UI_SOURCE=".venv/lib/python3.12/site-packages/splunk_add_on_ucc_framework/package/appserver"
OUTPUT_DIR="output/TA-suhlabs-eMASS"

if [ ! -d "$UCC_UI_SOURCE" ]; then
    echo "ERROR: UCC UI source not found at $UCC_UI_SOURCE"
    exit 1
fi

if [ ! -d "$OUTPUT_DIR" ]; then
    echo "ERROR: Output directory not found. Run 'ucc-gen build' first."
    exit 1
fi

# Protect the custom globalConfig.json that ucc-gen just wrote.
# Strategy: save it to a known local path BEFORE the wildcard cp overwrites it,
# then copy it back immediately after.
GC_FILE="$OUTPUT_DIR/appserver/static/js/build/globalConfig.json"
GC_SAVED="$OUTPUT_DIR/.gc_backup.json"

if [ -f "$GC_FILE" ]; then
    echo "Saving generated globalConfig.json (tabs: $(jq -r '.pages.configuration.tabs[].name // .pages.configuration.tabs[].type' "$GC_FILE" | tr '\n' ' '))..."
    cp "$GC_FILE" "$GC_SAVED"
else
    echo "WARNING: globalConfig.json not found before static copy — proxy tab may be missing"
fi

# Copy static content if it exists
if [ -d "$UCC_UI_SOURCE/static" ]; then
    echo "Copying static assets..."
    cp -r "$UCC_UI_SOURCE/static/"* "$OUTPUT_DIR/appserver/static/"
fi

# Restore the protected globalConfig.json
if [ -f "$GC_SAVED" ]; then
    echo "Restoring generated globalConfig.json..."
    cp "$GC_SAVED" "$GC_FILE"
    rm -f "$GC_SAVED"
    echo "  Tabs now: $(jq -r '.pages.configuration.tabs[].name // .pages.configuration.tabs[].type' "$GC_FILE" | tr '\n' ' ')"
else
    echo "WARNING: No saved globalConfig.json found to restore"
fi

# Copy redirect.html (critical for UI routing)
if [ -f "$UCC_UI_SOURCE/templates/redirect.html" ]; then
    echo "Copying redirect.html..."
    mkdir -p "$OUTPUT_DIR/appserver/templates"
    cp "$UCC_UI_SOURCE/templates/redirect.html" "$OUTPUT_DIR/appserver/templates/"
fi

# Do NOT copy base.html to avoid overwriting our custom one

echo "✓ Copied UI files successfully"
echo "  JS files: $(find $OUTPUT_DIR/appserver/static/js/build -name '*.js' | wc -l)"
echo "  Total appserver files: $(find $OUTPUT_DIR/appserver -type f | wc -l)"

# ── AppInspect: inject python.required = python3 ────────────────────────────
# Fixes: check_admin_external_restmap_conf_python_required
#        check_modular_inputs_python_required

RESTMAP_CONF="$OUTPUT_DIR/default/restmap.conf"
INPUTS_CONF="$OUTPUT_DIR/default/inputs.conf"

echo "Patching python.required into generated conf files..."

# restmap.conf — inject python.required = 3.13 after each [admin_external:*] stanza
# Uses Python for reliable cross-platform injection (avoids GNU/BSD sed differences)
if [ -f "$RESTMAP_CONF" ]; then
    if grep -q 'python.required' "$RESTMAP_CONF"; then
        echo "  restmap.conf: python.required already present"
    else
        python3 - <<'EOF'
import re, sys
with open("output/TA-suhlabs-eMASS/default/restmap.conf", "r") as f:
    content = f.read()
content = re.sub(
    r'(\[admin_external:[^\]]+\])',
    r'\1\npython.required = 3.13',
    content
)
with open("output/TA-suhlabs-eMASS/default/restmap.conf", "w") as f:
    f.write(content)
EOF
        echo "  restmap.conf: injected python.required"
    fi
else
    echo "  WARNING: restmap.conf not found"
fi

# inputs.conf — inject python.required = 3.13 after each stanza header
if [ -f "$INPUTS_CONF" ]; then
    if grep -q 'python.required' "$INPUTS_CONF"; then
        echo "  inputs.conf: python.required already present"
    else
        python3 - <<'EOF'
import re, sys
with open("output/TA-suhlabs-eMASS/default/inputs.conf", "r") as f:
    content = f.read()
content = re.sub(
    r'(\[[^\]]+\])',
    r'\1\npython.required = 3.13',
    content
)
with open("output/TA-suhlabs-eMASS/default/inputs.conf", "w") as f:
    f.write(content)
EOF
        echo "  inputs.conf: injected python.required"
    fi
else
    echo "  WARNING: inputs.conf not found"
fi

echo "✓ python.required injection complete"
