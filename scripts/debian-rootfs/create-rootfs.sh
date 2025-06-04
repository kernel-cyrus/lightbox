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
sudo umount rootfs/proc
sudo umount rootfs/sys
sudo rm -rf rootfs

# Start
mkdir rootfs

# Create rootfs with multistrap
sudo multistrap -a arm64 -f debian-arm64.conf -d rootfs

# Prepare arm64 qemu runtime
arch=$(uname -m)
if [[ "$arch" != arm* && "$arch" != aarch64 ]]; then
    sudo cp /usr/bin/qemu-aarch64-static ./rootfs/usr/bin/
fi

# Prepare chroot
sudo mount -t proc none rootfs/proc
sudo mount -t sysfs none rootfs/sys

# Post pkg install
sudo chroot rootfs bash -c "dpkg --configure -a"
sudo chroot rootfs bash -c "dpkg --configure -a" # try a again to fix dependency issue

# Set default password
sudo chroot rootfs bash -c "echo root:root | chpasswd"

# Finish chroot stuff
sudo umount rootfs/proc
sudo umount rootfs/sys

# Change permission
sudo chown "$(id -u):$(id -g)" -R rootfs

# Create init
ln -snf sbin/init rootfs/init

# Setup network interface
echo "auto eth0" >> rootfs/etc/network/interfaces
echo "iface eth0 inet dhcp" >> rootfs/etc/network/interfaces

# Setup DNS server
touch rootfs/etc/resolv.conf
echo "nameserver 223.5.5.5       # AliDNS" >> rootfs/etc/resolv.conf
echo "nameserver 119.29.29.29    # DNSPod" >> rootfs/etc/resolv.conf
echo "nameserver 114.114.114.114 # 114DNS" >> rootfs/etc/resolv.conf

