Lightbox
=============================

Lightbox is an aarch64 qemu based kernel running and debug environment for the linux kernel.

Everything is intergrated and configured ready to run.

You can start to run and debug the linux kernel from the very first assembly code just with the `start-kernel.sh` script.

![Snapshot](https://raw.githubusercontent.com/kernel-cyrus/lightbox/master/snapshots/snapshot.png)

Both linux kernel and android common kernel are supported, and you can choose to use gdb-tui or ddd as the debugger's front-end.

The envionment include:
- prebuilt aarch64 qemu excutables (for x86 host)
- prebuilt aarch64 gdb with tui enabled (for x86 host)
- prebuilt aarch64 initramfs image
- support running with linux kernel
- support running with android common kernel
- support debug with gdb for aarch64
- support debug with ddd for aarch64
- support 9pfs share folder
- support networking by default
- support boot debian rootfs

Host environment tested: 
- Intel x86 PC + Ubuntu 20.04 (OK)
- Raspberry Pi 4B + Ubuntu 22.04 (OK)
- Macbook M1 + UTM (virtual machine) + Ubuntu 20.04 (OK)

Setup Environment
-----------------------------

**for x86 Host**

To build arm64 linux kernel on x86 machine, you need install the cross-compiler:

```
sudo apt install gcc-aarch64-linux-gnu
```

gdb and qemu are already built as binaries. lightbox will just use the prebuild ones, and nothing else is needed.

**for arm64 Host**

When your host is arm64 (raspberry pi or macbook m1), you need install GDB and QEMU:

```
sudo apt install gdb
sudo apt install qemu qemu-system-arm
```

**Install tmux**

For better experience, lightbox will use tmux as default terminal when it is installed.

To install tmux:

```
sudo apt install tmux
```

When tmux is not installed, lightbox will use gnome as default termninal, you can also choose to use xfce4 or cli terminal seperately.

**Install DDD**

By default, lightbox use gdb as default debugger with tui. You can also choose to use ddd as debugger with gui. 

To install ddd:

```
sudo apt install ddd
```

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
    --kernel=<kernel dir>           # kernel repo dir            (REQUIRED)
    --initrd=<initrd image path>    # initrd file (.cpio.gz)     (OPTIONAL)
    --rootfs=<rootfs image path>    # rootfs file (.ext4)        (OPTIONAL)
    --with=<"gdb" or "ddd">         # use gdb or ddd as debugger (OPTIONAL)
    --append=<kernel cmdline>       # append extra cmdline       (OPTIONAL)
    --share=<share folder path>     # host share folder          (OPTIONAL)
    --terminal=<terminal to use>    # default: tmux              (OPTIONAL)
                                    # options: tmux / gnome / xfce4 / cli-qemu / cli-gdb
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
**Run with your own initramfs image or ext4 rootfs**
```
./start-kernel --kernel=<kernel_dir> --initrd=<cpio.gz initramfs file path>
./start-kernel --kernel=<kernel_dir> --rootfs=<ext4/raw/qcow2 image path>
```
debian rootfs image is suported:

- [debian-12-nocloud-arm64.qcow2](https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-nocloud-arm64.qcow2)
- [debian-12-nocloud-arm64.raw](https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-nocloud-arm64.raw)

**Customize kernel cmdline**
```
./start-kernel --kernel=<kernel_dir> --append="earlycon"
```
**Share host files**

The default share folder is "./host-share", and it will be automatically mounted when guest os bootup.

You can also use a custom share folder:

```
./start-kernel --kernel=<kernel_dir> --share="./host-share"
```

**Support for gnome and xfce4 terminals**

When tmux is not installed, lightbox will use gnome as default terminal.

In some cases when your host os is not GNOME, you may choose to use xfce4 terminal:

```
./start-kernel --kernel=<kernel_dir> --terminal="xfce4"
```

**Run in cli mode**

For pure cli environment like ssh without desktop display, and also tmux is not installed, you can start qemu and gdb seperately.

Start qemu from one cli session:

```
./start-kernel --kernel=<kernel_dir> --terminal="cli-qemu"
```

And then start gdb in another cli session:

```
./start-kernel --kernel=<kernel_dir> --terminal="cli-gdb"
```

**Create debian rootfs**

By default, lightbox use a prebuilt busybox initrd image, you can download or create a debian rootfs

see: [scripts/debian-rootfs/README.md](https://github.com/kernel-cyrus/lightbox/tree/master/scripts/debian-rootfs)

Contact
-----------------------------

Author: Cyrus Huang

Github: <https://github.com/kernel-cyrus/lightbox>
