# Check dependency
if ! command -v multistrap >/dev/null 2>&1; then
    echo "Installing multistrap..."
    sudo apt update && sudo apt install multistrap -y
fi

if ! command -v qemu-aarch64-static >/dev/null 2>&1; then
    echo "Installing multistrap..."
    sudo apt update && sudo apt install qemu-aarch64-static -y
fi

# Remove old rootfs directory
sudo rm -rf rootfs

# Create rootfs with multistrap
sudo multistrap -a arm64 -f debian-arm64.conf -d rootfs

# Create init
sudo ln -snf sbin/init rootfs/init

# Setup arm64 excution environment
sudo cp /usr/bin/qemu-aarch64-static ./rootfs/usr/bin/

# Patch rootfs with overlay files
sudo cp -r rootfs-overlays/. rootfs/

# Set passowrd
sudo chroot rootfs bash -c "echo root:root | chpasswd"

# Change permission
sudo chown "$(id -u):$(id -g)" -R rootfs

