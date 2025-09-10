GDB_CMDS=(
  "-ex" "set architecture i386:x86-64"
  "-ex" "set disassemble-next-line on"
  "-ex" "target remote :1234"
  "-ex" "b start_kernel"
  "-ex" "c"
)

exec gdb-multiarch "vmlinux" "${GDB_CMDS[@]}"
