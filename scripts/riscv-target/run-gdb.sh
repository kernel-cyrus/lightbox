#!/bin/bash
# run-gdb.sh — Start GDB, connect to QEMU, and on exit gracefully quit QEMU via QMP, then close tmux.

set -euo pipefail

VMLINUX="vmlinux"
GDB_PORT="1234"
SESSION="qemu-gdb"
QMP_SOCK="/tmp/qemu-qmp.sock"

# Pick a GDB with RISC-V support
if command -v riscv64-linux-gnu-gdb &>/dev/null; then
  GDB_BIN="riscv64-linux-gnu-gdb"
else
  GDB_BIN="gdb-multiarch"
fi

# Helper: send a QMP command over the UNIX socket
qmp_cmd() {
  local json="$1"
  if [ -S "$QMP_SOCK" ]; then
    # QMP expects an initial greeting; socat will read it and then we send our cmd.
    # Using 'socat -' to write JSON and ignore output.
    printf '%s\n' "$json" | socat - UNIX-CONNECT:"$QMP_SOCK" >/dev/null 2>&1 || true
  fi
}

# Ensure socat exists for QMP control (only needed at cleanup)
if ! command -v socat >/dev/null 2>&1; then
  echo "[WARN] 'socat' is not installed. QEMU may not exit gracefully after GDB quits."
  echo "[WARN] Install it (e.g., 'sudo apt install socat') for graceful QMP shutdown."
fi

echo "[INFO] Launching $GDB_BIN and connecting to :$GDB_PORT..."
# Run GDB; when it exits (quit/EOF), proceed to cleanup
"$GDB_BIN" "$VMLINUX" \
  -ex "set pagination off" \
  -ex "set confirm off" \
  -ex "target remote :$GDB_PORT" \
  -ex "source scripts/gdb/vmlinux-gdb.py" \
  -ex "hbreak start_kernel" \
  -ex "continue" || true

echo "[INFO] GDB exited. Requesting QEMU graceful quit via QMP..."
qmp_cmd '{ "execute": "quit" }'

# Give QEMU a brief moment to exit gracefully (non-fatal if it has already exited)
sleep 0.2

echo "[INFO] Closing tmux session '$SESSION'..."
tmux kill-session -t "$SESSION" >/dev/null 2>&1 || true

