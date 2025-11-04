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
OUTPUT_DIR="output/TA-securepro-eMASS"

if [ ! -d "$UCC_UI_SOURCE" ]; then
    echo "ERROR: UCC UI source not found at $UCC_UI_SOURCE"
    exit 1
fi

if [ ! -d "$OUTPUT_DIR" ]; then
    echo "ERROR: Output directory not found. Run 'ucc-gen build' first."
    exit 1
fi

# Copy appserver files
cp -r "$UCC_UI_SOURCE" "$OUTPUT_DIR/"

echo "✓ Copied UI files successfully"
echo "  JS files: $(find $OUTPUT_DIR/appserver/static/js/build -name '*.js' | wc -l)"
echo "  Total appserver files: $(find $OUTPUT_DIR/appserver -type f | wc -l)"
