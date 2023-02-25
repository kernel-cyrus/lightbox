Lightbox
=============================

Lightbox is an aarch64 qemu based kernel running and debug environment for the linux kernel.

Everything is intergrated and configured ready to run.

You can start to run and debug the linux kernel from the very first assembly code just with the `start-kernel.sh` script.

![Snapshot](https://raw.githubusercontent.com/kernel-cyrus/lightbox/master/snapshots/snapshot.png)

Both linux kernel and android common kernel are supported, and you can choose to use gdb-tui or ddd as the debugger's front-end.

The envionment include:
- prebuilt aarch64 qemu excutables
- prebuilt aarch64 gdb with tui enabled
- prebuilt aarch64 initramfs image
- support running with linux kernel
- support running with android common kernel
- support debug with gdb for aarch64
- support debug with ddd for aarch64
- support 9pfs share folder

Host environment tested: x86 PC + Ubuntu 20.04

Download Lightbox
-----------------------------

```
git clone https://github.com/kernel-cyrus/lightbox.git
```

Build Linux Kernel
-----------------------------

**Download linux kernel**
```
git clone https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
```
**Apply a patch**
```
cd linux
git apply .../lightbox/patches/linux-mainline.patch
```
**Build the kernel**
```
ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- make lightbox_defconfig
ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- make Image scripts_gdb
```

Build Android Common Kernel
-----------------------------

**Download android common kernel**
```
repo init -u https://android.googlesource.com/kernel/manifest -b common-android-mainline
repo sync
```
**Apply a patch**
```
cd common
git apply .../lightbox/patches/android-mainline.patch
```
**Build the kernel**
```
BUILD_CONFIG=common/build.config.lightbox build/build.sh
```

Start Kernel
-----------------------------

**Command Format**
```
./start-kernel.sh
    --kernel=<kernel dir>           # kernel repo dir
    --initrd=<initrd file path>     # initrd file path "./prebuilts/rootfs/initrd_aarch64.cpio.gz"
    --with=<"gdb" or "ddd">         # use gdb or ddd as debugger
    --append=<kernel cmdline>       # append extra cmdline
    --share=<share folder path>     # host share folder,     default:"./host-share"
```
**Run kernel with gdb**
```
./start-kernel --kernel=<kernel_dir> --with=gdb
```
**Run kernel with ddd**
```
sudo apt install ddd
./start-kernel --kernel=<kernel_dir> --with=ddd
```
**Run with your own initramfs image**
```
./start-kernel --kernel=<kernel_dir> --initrd=<initramfs_file_path>
```
**Customize kernel cmdline**
```
./start-kernel --kernel=<kernel_dir> --append="earlycon"
```
**Share host files**
The default
```
./start-kernel --kernel=<kernel_dir> --share="./host-share"
```

Contact
-----------------------------

Author: Cyrus Huang

Github: <https://github.com/kernel-cyrus/lightbox>
