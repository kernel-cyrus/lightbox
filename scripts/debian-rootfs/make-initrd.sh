#!/bin/bash

# Exit on error
set -e

# === Input directory ===
ROOTFS_DIR="${1:-./rootfs}"
OUTPUT_FILE=debian-arm64.cpio.gz

# === Check directory ===
if [ ! -d "$ROOTFS_DIR" ]; then
    echo "❌ Directory '$ROOTFS_DIR' not found."
    exit 1
fi

echo "📦 Packing directory: $ROOTFS_DIR"
echo "🧵 Output file: $OUTPUT_FILE"

# === Create cpio.gz archive ===
cd "$ROOTFS_DIR"
find . -print0 | cpio --null --create --verbose --format=newc -R root:root | gzip --best > "../$OUTPUT_FILE"
cd - >/dev/null

echo "✅ Done: $OUTPUT_FILE created"

