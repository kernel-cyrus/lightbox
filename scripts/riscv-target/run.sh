#!/bin/bash
# run-debug.sh — Open a tmux session with two panes: left runs QEMU, right runs GDB.

set -euo pipefail

SESSION="qemu-gdb"

# If a session already exists, just attach
if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "[INFO] tmux session '$SESSION' already exists. Attaching..."
  exec tmux attach -t "$SESSION"
fi

# Create session and run QEMU on the left pane
tmux new-session -d -s "$SESSION" -n debug
tmux send-keys -t "$SESSION" "./run-qemu.sh" C-m

# Split right pane and run GDB there
tmux split-window -h -t "$SESSION"
tmux send-keys -t "$SESSION" "./run-gdb.sh" C-m

# Arrange layout and attach
tmux select-layout -t "$SESSION" even-horizontal
tmux attach -t "$SESSION"

