export ARCH=x86_64
export CROSS_COMPILE=x86_64-linux-gnu-
make -j$(nproc) bzImage modules
\cp drivers/tests/*/*.ko host-share
echo "sudo mount -t 9p -o trans=virtio hostshare /mnt"
