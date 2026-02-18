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

# Copy appserver/static files (JS/CSS/images)
# Ensure destination structure exists
mkdir -p "$OUTPUT_DIR/appserver/static"

# Copy static content if it exists
if [ -d "$UCC_UI_SOURCE/static" ]; then
    echo "Copying static assets..."
    cp -r "$UCC_UI_SOURCE/static/"* "$OUTPUT_DIR/appserver/static/"
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
