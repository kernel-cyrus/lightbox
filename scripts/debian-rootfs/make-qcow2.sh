#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# === Configuration ===
ROOTFS_DIR=${1:-./rootfs}        # Rootfs directory (default: ./rootfs)
OUTPUT_IMG=debian-arm64.qcow2   # Output image filename
SIZE=2G                          # Image size
MOUNT_DIR=/mnt/rootfs-temp       # Temporary mount point

# === Pre-checks ===
if [ ! -d "$ROOTFS_DIR" ]; then
    echo "❌ Rootfs directory '$ROOTFS_DIR' not found."
    exit 1
fi

if ! command -v qemu-img &>/dev/null; then
    echo "❌ qemu-img not found. Please install qemu-utils."
    exit 1
fi

# === Create the qcow2 image ===
echo "🧱 Creating $SIZE qcow2 image: $OUTPUT_IMG"
qemu-img create -f qcow2 "$OUTPUT_IMG" "$SIZE"

# === Connect the image using NBD ===
sudo modprobe nbd max_part=8
sudo qemu-nbd --connect=/dev/nbd0 "$OUTPUT_IMG"

# === Partition and format the image ===
echo "📦 Partitioning and formatting..."
sudo parted /dev/nbd0 --script mklabel msdos
sudo parted /dev/nbd0 --script mkpart primary ext4 1MiB 100%
sudo mkfs.ext4 /dev/nbd0p1

# === Mount and copy the rootfs ===
echo "📂 Mounting and copying rootfs..."
sudo mkdir -p "$MOUNT_DIR"
sudo mount /dev/nbd0p1 "$MOUNT_DIR"
sudo cp -a "$ROOTFS_DIR"/* "$MOUNT_DIR/"

# === Cleanup ===
echo "🧹 Cleaning up..."
sudo umount "$MOUNT_DIR"
sudo qemu-nbd --disconnect /dev/nbd0
sudo rmdir "$MOUNT_DIR"

echo "✅ Image created successfully: $OUTPUT_IMG"

