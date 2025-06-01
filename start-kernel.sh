KERNEL=""
INITRD=$(realpath ./prebuilts/rootfs/initrd_aarch64.cpio.gz)
DTB=$(realpath ./prebuilts/dts/lightbox.dtb)
CMDLINE=""
DEBUGGER="gdb"
SHARE_FOLDER=$(realpath ./host-share)

if type tmux >/dev/null 2>&1; then
    TERMINAL="tmux"
else
    TERMINAL="gnome"
fi

PARAMS="$@"

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
        -rootfs=*|--rootfs=*)
            ROOTFS="${i#*=}"
            shift # past argument=value
            ;;
        -with=*|--with=*)
            DEBUGGER="${i#*=}"
            shift # past argument=value
            ;;
        -append=*|--append=*)
            CMDLINE="${i#*=}"
            shift # past argument=value
            ;;
        -share=*|--share=*)
            SHARE_FOLDER="${i#*=}"
            shift # past argument=value
            ;;
        -terminal=*|--terminal=*)
            TERMINAL="${i#*=}"
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
    return 0
fi

if [ ! -d "$KERNEL" ]; then
    echo "ERROR: Directory not found: --kernel=<path>"
    return 0
fi

if [ -d "$KERNEL/common" ]; then
    KERNEL_TYPE=android
else
    KERNEL_TYPE=linux
fi

KERNEL_DIR=$(cd ${KERNEL}; pwd)

if [ $KERNEL_TYPE == "android" ]; then
    KERNEL_OUT=${KERNEL_DIR}/out/$(ls ${KERNEL_DIR}/out/ | grep android)
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

if [[ "$(uname -m)" == "aarch64" ]]; then
    GDB_EXEC=gdb
    GDB_DATA=/usr/share/gdb
    QEMU_EXEC=qemu-system-aarch64
else
    GDB_DIR=$(cd ./prebuilts/gdb; pwd)
    GDB_EXEC=${GDB_DIR}/usr/local/bin/aarch64-linux-gnu-gdb
    GDB_DATA=${GDB_DIR}/usr/local/share/gdb
    QEMU_EXEC=$(realpath ./prebuilts/qemu/bin/qemu-system-aarch64)
fi

if [ -n "$ROOTFS" ]; then
    ROOTFS_PATH=$(realpath ${ROOTFS})
    if [[ "$ROOTFS" == *.qcow2 ]]; then
        ROOTFS_FORMAT="qcow2"
	ROOTFS_DEVICE="/dev/vda1"
    else
        ROOTFS_FORMAT="raw"
	ROOTFS_DEVICE="/dev/vda"
    fi
    ROOTFS_PARAM="-drive if=none,file=${ROOTFS_PATH},format=${ROOTFS_FORMAT},id=hd0 -device virtio-blk-device,drive=hd0"
    ROOTFS_BOOTARGS="root=${ROOTFS_DEVICE}"
    echo "Using rootfs image: ${ROOTFS_PATH}"
else
    INITRD_PATH=$(realpath ${INITRD})
    ROOTFS_PARAM="-initrd ${INITRD_PATH}"
    ROOTFS_BOOTARGS=""
    echo "Using initrd image: ${INITRD_PATH}"
fi

DTB_PATH=$(realpath ${DTB})
SHARE_PARAM="-fsdev local,security_model=mapped,id=fsdev0,path=$(realpath ${SHARE_FOLDER}) -device virtio-9p-pci,id=fs0,fsdev=fsdev0,mount_tag=hostshare"

if [[ $TERMINAL == cli* ]]; then
    DEBUG_PORT=12880
else
    DEBUG_PORT=$((10000 + $RANDOM % 10000))
fi

QEMU_TITTLE="QEMU@localhost:$DEBUG_PORT"

QEMU_CMD="${QEMU_EXEC}          \
 -machine virt,gic_version=3    \
 -cpu cortex-a72                \
 -m 1024                        \
 -smp 8                         \
 -kernel ${KERNEL_IMAGE}        \
 ${ROOTFS_PARAM}                \
 ${SHARE_PARAM}                 \
 -serial mon:stdio              \
 -display none                  \
 -gdb tcp::${DEBUG_PORT}        \
 -S -append '${ROOTFS_BOOTARGS} ${CMDLINE} earlycon=pl011,0x9000000 nokaslr'"

if [ $TERMINAL == "gnome" ]; then
    gnome-terminal -t "$QEMU_TITLE" -- bash -c "$QEMU_CMD" &
elif [ $TERMINAL == "xfce4" ]; then
    xfce4-terminal -T "$QEMU_TITLE" --command "bash -c \"$QEMU_CMD\"" &
elif [ $TERMINAL == "cli-qemu" ]; then
    echo "QEMU start, waiting for GDB connection..."
    bash -c "$QEMU_CMD"
    exit
elif [ $TERMINAL == "cli-gdb" ]; then
    echo "Try to connect QEMU..."
elif [ $TERMINAL == "tmux" ]; then
    DIR=$(pwd)
    tmux kill-session -t lightbox
    tmux new-session -d -s lightbox "bash"
    tmux send-keys -t lightbox "cd $DIR" C-m
    tmux send-keys -t lightbox "source ./start-kernel.sh ${PARAMS/tmux/cli-qemu} --terminal=cli-qemu" C-m
    tmux split-window -h "bash"
    tmux send-keys -t lightbox "cd $DIR" C-m
    tmux send-keys -t lightbox "source ./start-kernel.sh ${PARAMS/tmux/cli-gdb} --terminal=cli-gdb" C-m
    tmux attach-session -d -t lightbox
    tmux kill-session -t lightbox
    return 0
else
    echo "Invalid param: --terminal=\"$TERMINAL\", please use \"tmux\", \"gnome\", \"xfce4\", \"cli-qemu\", \"cli-gdb\""
    return 0
fi

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
tmux kill-session -t lightbox
