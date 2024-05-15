Lightbox
=============================

Lightbox is an aarch64 qemu based kernel running and debug environment for the linux kernel.

Everything is intergrated and configured ready to run.

You can start to run and debug the linux kernel from the very first assembly code just with the `start-kernel.sh` script.

![Snapshot](https://raw.githubusercontent.com/kernel-cyrus/lightbox/master/snapshots/snapshot.png)

Both linux kernel and android common kernel are supported, and you can choose to use gdb-tui or ddd as the debugger's front-end.

The envionment include:
- prebuilt aarch64 qemu excutables (is used for x86 host)
- prebuilt aarch64 gdb with tui enabled (is used for x86 host)
- prebuilt aarch64 initramfs image
- support running with linux kernel
- support running with android common kernel
- support debug with gdb for aarch64
- support debug with ddd for aarch64
- support 9pfs share folder

Host environment tested: 
- x86 PC + Ubuntu 20.04 (OK)
- Raspberry Pi 4B + Ubuntu 22.04 (OK)
- Macbook Air M1 + UTM (virtual machine) + Ubuntu 20.04 (OK)

Install GDB and QEMU (for ARM64 Host Only)
-----------------------------

When you run on ARM64 host, you need install GDB and QEMU first:

```
sudo apt install gdb
sudo apt install qemu qemu-system-arm
```

x86 host will use the prebuild binary, you don't need to install anything.

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
    --initrd=<initrd file path>     # initrd file                (OPTIONAL)
    --with=<"gdb" or "ddd">         # use gdb or ddd as debugger (OPTIONAL)
    --append=<kernel cmdline>       # append extra cmdline       (OPTIONAL)
    --share=<share folder path>     # host share folder          (OPTIONAL)
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

The default share folder is "./host-share", and it will be automatically mounted when guest os bootup.

You can also use a custom share folder:

```
./start-kernel --kernel=<kernel_dir> --share="./host-share"
```

**Support for gnome and xfce4 terminal**

By default, lightbox uses gnome terminal, in some cases you may choose to use xfce4 terminal:

```
./start-kernel --kernel=<kernel_dir> --terminal="xfce4"
```

**Run in cli mode**

For pure cli environment like ssh without desktop display, you can start qemu and gdb seperately.

Start qemu from one cli session:

```
./start-kernel --kernel=<kernel_dir> --terminal="cli-qemu"
```

And then start gdb in another cli session:

```
./start-kernel --kernel=<kernel_dir> --terminal="cli-gdb"
```

Contact
-----------------------------

Author: Cyrus Huang

Github: <https://github.com/kernel-cyrus/lightbox>
