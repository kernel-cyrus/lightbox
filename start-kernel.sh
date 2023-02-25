KERNEL=""
INITRD=$(realpath ./prebuilts/rootfs/initrd_aarch64.cpio.gz)
DEBUGGER="gdb"
BOOTARGS=""
SHARE_FOLDER=$(realpath ./host-share)

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
        -with=*|--with=*)
            DEBUGGER="${i#*=}"
            shift # past argument=value
            ;;
        -append=*|--append=*)
            BOOTARGS="${i#*=}"
            shift # past argument=value
            ;;
        -share=*|--share=*)
            SHARE_FOLDER="${i#*=}"
            shift # past argument=value
            ;;
        *)
            echo "Invalid argument: ${i#*=}, please check your input."
            return 0
            ;;
    esac
done

if [ -z "$KERNEL" ]; then
    echo "Please pass the kernel path: --kernel=<path>"
    return
fi

if [ ! -d "$KERNEL" ]; then
    echo "ERROR: Directory not found: --kernel=<path>"
    return
fi

if [ -d "$KERNEL/common" ]; then
    KERNEL_TYPE=android
else
    KERNEL_TYPE=linux
fi

KERNEL_DIR=$(cd ${KERNEL}; pwd)

if [ $KERNEL_TYPE == "android" ]; then
    KERNEL_OUT=${KERNEL_DIR}/out/$(ls ${KERNEL_DIR}/out/)
    KERNEL_SOURCE=${KERNEL_DIR}/common
    KERNEL_IMAGE=${KERNEL_OUT}/dist/Image
    KERNEL_VMLINUX=${KERNEL_OUT}/common/vmlinux
    KERNEL_SCRIPTS=${KERNEL_OUT}/common/vmlinux-gdb.py
    RELOC_SECTIONS="-s .head.text 0x40200000 -s .text 0x40210000 -s .init.text 0x42870000"
elif [ $KERNEL_TYPE == "linux" ]; then
    KERNEL_OUT=${KERNEL_DIR}
    KERNEL_SOURCE=${KERNEL_DIR}
    KERNEL_IMAGE=${KERNEL_OUT}/arch/arm64/boot/Image
    KERNEL_VMLINUX=${KERNEL_OUT}/vmlinux
    KERNEL_SCRIPTS=${KERNEL_OUT}/vmlinux-gdb.py
    RELOC_SECTIONS="-s .head.text 0x40200000 -s .text 0x40210000 -s .init.text 0x418b0000"
fi

GDB_DIR=$(cd ./prebuilts/gdb; pwd)
GDB_EXEC=${GDB_DIR}/usr/local/bin/aarch64-linux-gnu-gdb
GDB_DATA=${GDB_DIR}/usr/local/share/gdb
QEMU_EXEC=$(realpath ./prebuilts/qemu/bin/qemu-system-aarch64)
INITRD_PATH=$(realpath ${INITRD})
DEBUG_PORT=$((10000 + $RANDOM % 10000))
SHARE_PARAM="-fsdev local,security_model=passthrough,id=fsdev0,path=$(realpath ${SHARE_FOLDER}) -device virtio-9p-device,id=fs0,fsdev=fsdev0,mount_tag=hostshare"

gnome-terminal --               \
${QEMU_EXEC}                    \
 -machine virt                  \
 -cpu cortex-a72                \
 -m 1024                        \
 -smp 4                         \
 -initrd ${INITRD_PATH}         \
 -kernel ${KERNEL_IMAGE}        \
 ${SHARE_PARAM}                 \
 -serial stdio                  \
 -display none                  \
 -gdb tcp::${DEBUG_PORT}        \
 -S -append "${BOOTARGS} earlycon=pl011,0x9000000 nokaslr"

if [ $DEBUGGER == "gdb" ]; then

    (cd ${KERNEL_SOURCE}; ${GDB_EXEC}                           \
     -data-directory ${GDB_DATA}                                \
     -ex "add-auto-load-safe-path ${KERNEL_SCRIPTS}"            \
     -ex "set confirm off"                                      \
     -ex "file ${KERNEL_VMLINUX}"                               \
     -ex "add-symbol-file ${KERNEL_VMLINUX} ${RELOC_SECTIONS}"  \
     -ex "target remote localhost:${DEBUG_PORT}"                \
     -ex "b * 0x40200000 thread 1"                              \
     -ex "tui enable"                                           \
     -ex "continue"                                             \
     -quiet)

elif [ $DEBUGGER == "ddd" ]; then

    DDD_SCRIPT=$(realpath ./ddd.script)

    rm -f ${DDD_SCRIPT}
    touch ${DDD_SCRIPT}

    echo "add-auto-load-safe-path ${KERNEL_SCRIPTS}" >> ${DDD_SCRIPT}
    echo "set confirm off" >> ${DDD_SCRIPT}
    echo "file ${KERNEL_VMLINUX}" >> ${DDD_SCRIPT}
    echo "add-symbol-file ${KERNEL_VMLINUX} ${RELOC_SECTIONS}" >> ${DDD_SCRIPT}
    echo "target remote localhost:${DEBUG_PORT}" >> ${DDD_SCRIPT}
    echo "b * 0x40200000 thread 1" >> ${DDD_SCRIPT}
    echo "continue" >> ${DDD_SCRIPT}

    (cd ${KERNEL_SOURCE}; ddd --debugger ${GDB_EXEC} --command ${DDD_SCRIPT})

    rm -f ${DDD_SCRIPT}
fi

killall qemu-system-aarch64