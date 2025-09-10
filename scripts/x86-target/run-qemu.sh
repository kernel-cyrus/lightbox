qemu-system-x86_64 \
  -m 2048 \
  -smp 2 \
  -machine accel=tcg \
  -kernel arch/x86_64/boot/bzImage \
  -drive file=debian-12-nocloud-amd64.qcow2,if=virtio,format=qcow2 \
  -append "root=/dev/vda1 rw console=ttyS0 earlycon=uart,io,0x3f8,115200 nokaslr" \
  -serial mon:stdio \
  -nographic \
  -s -S

