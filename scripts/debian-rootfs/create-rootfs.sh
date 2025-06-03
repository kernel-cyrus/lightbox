# Remove old rootfs directory
sudo rm -rf rootfs

# Create rootfs with multistrap
sudo multistrap -a arm64 -f debian-arm64.conf -d rootfs

# Create init
sudo ln -snf sbin/init rootfs/init

# Set permission
sudo chown "$(id -u):$(id -g)" -R rootfs

# Set passowrd
sudo chroot rootfs bash -c "echo root:root | chpasswd"

# Setup network interface
echo "auto eth0" >> rootfs/etc/network/interfaces
echo "iface eth0 inet dhcp" >> rootfs/etc/network/interfaces

# Setup DNS server
touch rootfs/etc/resolv.conf
echo "nameserver 223.5.5.5       # AliDNS" >> rootfs/etc/resolv.conf
echo "nameserver 119.29.29.29    # DNSPod" >> rootfs/etc/resolv.conf
echo "nameserver 114.114.114.114 # 114DNS" >> rootfs/etc/resolv.conf
