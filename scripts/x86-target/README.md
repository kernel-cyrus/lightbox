1. copy all .sh files to kernel source dir

2. prepare debian rootfs
wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-nocloud-amd64.qcow2

3. build kernel
source build.sh

4. start qemu
source run-qemu.sh
(ctrl-A+X to exit qemu)

5. start gdb
source run-gdb.sh

