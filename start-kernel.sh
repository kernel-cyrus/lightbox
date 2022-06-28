KERNEL="../codebase/android-12/kernel-5.10/"
INITRD="./prebuilts/rootfs/initrd_aarch64.cpio.gz"

for i in "$@"; do
    case $i in
        -kernel=*|--kernel=*)
            KERNEL="${i#*=}"
            shift # past argument=value
            ;;
         -initrd=*|--initrd=*)
            INITRD="${i#*=}"
            shift # past argument=value
            ;;
        *)
            echo "Invalid argument: ${i#*=}, please check your input."
            return 0
            ;;
    esac
done

KERNEL_VERSION=android12-5.10

KERNEL_PATH=$(cd ${KERNEL}; pwd)

KERNEL_IMAGE=$KERNEL_PATH/out/$KERNEL_VERSION/dist/Image

KERNEL_VMLINUX=$KERNEL_PATH/out/$KERNEL_VERSION/common/vmlinux

GDB_SCRIPTS=$KERNEL_PATH/out/$KERNEL_VERSION/common/scripts/gdb/vmlinux-gdb.py

INITRD_PATH=${INITRD}

rm -rf ./lookup

mkdir ./lookup

mkdir ./lookup/out

mkdir ./lookup/out/$KERNEL_VERSION

ln -sfn $KERNEL_PATH/common ./lookup/out/$KERNEL_VERSION/common

ln -sfn $KERNEL_PATH/common ./lookup/common

SOURCE_PATH=./lookup

DEBUG_PORT=$((10000 + $RANDOM % 10000))

ln -sfn $KERNEL_PATH/common ./lookup/out/$KERNEL_VERSION/common

ln -sfn $KERNEL_PATH/common ./lookup/common

SOURCE_PATH=./lookup

DEBUG_PORT=$((10000 + $RANDOM % 10000))

gnome-terminal --                                           \
./prebuilts/qemu/usr/local/bin/qemu-system-aarch64          \
 -machine virt                                              \
 -cpu cortex-a72                                            \
 -m 1024                                                    \
 -smp 4                                                     \
 -initrd $INITRD_PATH                                       \
 -kernel $KERNEL_IMAGE                                      \
 -serial stdio                                              \
 -display none                                              \
 -gdb tcp::$DEBUG_PORT                                      \
 -S -append nokaslr

./prebuilts/gdb/usr/local/bin/aarch64-linux-gnu-gdb         \
 -directory $SOURCE_PATH                                    \
 -data-directory ./prebuilts/gdb/usr/local/share/gdb        \
 -ex "add-auto-load-safe-path $GDB_SCRIPTS"                 \
 -ex "set confirm off"                                      \
 -ex "file $KERNEL_VMLINUX"                                 \
 -ex "add-symbol-file $KERNEL_VMLINUX -s .head.text 0x40200000 -s .text 0x40210000 -s .init.text 0x42870000" \
 -ex "target remote localhost:$DEBUG_PORT"                  \
 -ex "b * 0x40200000 thread 1"                              \
 -ex "tui enable"                                           \
 -ex "continue"                                             \
 -quiet

rm -rf ./lookup

killall qemu-system-aarch64
