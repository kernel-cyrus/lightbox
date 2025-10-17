#!/bin/bash
# run-qemu.sh — Launch RISC-V QEMU with GDB stub and QMP for graceful exit.

set -euo pipefail

KERNEL_IMAGE="arch/riscv/boot/Image"
MEM="1G"
SMP="2"
GDB_PORT="1234"
QMP_SOCK="/tmp/qemu-qmp.sock"

echo "[INFO] Starting QEMU (GDB: tcp::$GDB_PORT, QMP: $QMP_SOCK)..."

# Ensure old QMP socket is gone
rm -f "$QMP_SOCK"

# Run QEMU in the foreground (tmux pane will own the process)
exec qemu-system-riscv64 \
  -machine virt -m "$MEM" -smp "$SMP" -nographic \
  -bios default \
  -kernel "$KERNEL_IMAGE" \
  -append "console=ttyS0 earlycon=sbi loglevel=8 ignore_loglevel nokaslr" \
  -S -gdb tcp::"$GDB_PORT" \
  -qmp unix:"$QMP_SOCK",server,nowait

