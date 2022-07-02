KERNEL_IMAGE=~/Workspace/codebase/linux-mainline/arch/arm64/boot/Image

KERNEL_VMLINUX=~/Workspace/codebase/linux-mainline/vmlinux

SOURCE_PATH=~/Workspace/codebase/linux-mainline

DEBUG_PORT=$((10000 + $RANDOM % 10000))


gnome-terminal --                                   \
./prebuilts/qemu/usr/local/bin/qemu-system-aarch64  \
 -machine virt                                      \
 -cpu cortex-a72                                    \
 -m 1024                                            \
 -smp 4                                             \
 -initrd ./prebuilts/rootfs/initrd_aarch64.cpio.gz  \
 -kernel $KERNEL_IMAGE                              \
 -serial stdio                                      \
 -display none                                      \
 -gdb tcp::$DEBUG_PORT                              \
 -S -append nokaslr

./prebuilts/gdb/usr/local/bin/aarch64-linux-gnu-gdb         \
 -directory=$SOURCE_PATH                                    \
 -data-directory=./prebuilts/gdb/usr/local/share/gdb        \
 -ex "add-auto-load-safe-path $SOURCE_PATH"                 \
 -ex "set confirm off"                                      \
 -ex "file $KERNEL_VMLINUX"                                 \
 -ex "add-symbol-file $KERNEL_VMLINUX -s .head.text 0x40200000 -s .text 0x40210000 -s .init.text 0x418b0000" \
 -ex "target remote localhost:$DEBUG_PORT"                  \
 -ex "b * 0x40200000 thread 1"                              \
 -ex "tui enable"                                           \
 -ex "continue"                                             \
 -quiet

killall qemu-system-aarch64
