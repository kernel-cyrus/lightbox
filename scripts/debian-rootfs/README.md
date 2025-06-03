**Downlaod debian rootfs**

./download-rootfs.sh (==> debian-12-nocloud-arm64.qcow2)

**Start lightbox**

source start-kernel.sh --kernel=... --rootfs=debian-12-nocloud-arm64.qcow2 (user: root)

**Create debian rootfs with multistrap**

./create-rootfs.sh (==> rootfs directory)

**Modify debian rootfs config**

vim ./debian-arm64.conf

**Make qcow2 image**

./make-qcow2.sh (==> debian-arm64.qcow2)

**Start lightbox**

source start-kernel.sh --kernel=... --rootfs=debian-arm64.qcow2 (user/pass: root/root)

**Make initrd image**

./make-initrd.sh (==> debian-arm64.cpio.gz)

**Start lightbox**

source start-kernel.sh --kernel=... --initrd=debian-arm64.cpio.gz (user/pass: root/root)
