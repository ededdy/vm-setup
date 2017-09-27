# vm-setup
 Setting up a virtual machine instance with qemu-kvm running vanilla kernel and a minimal Ubuntu userspace.
 
# Step 1 (Prepare disk images):
 Use this rudimentary script to prepare the root image for a ubuntu userspace
 which we can boot to using qemu.  We use a custom vanilla kernel underneath
 and we use this user-space to have our favourite tools to hack the custom
 kernel.  Then after we have prepared the disk images we can boot into it with
 the following command (below).

 i.e ./prepare-root.sh

# Step 2 (Configure and build min config vanilla kernel):
 1) mkdir kernel
 2) cd kernel && git clone git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
 3) cd linux
 4) make x86_64_defconfig
 5) make kvmconfig
 6) make -j 8

# Step 3 (Boot with qemu):
 qemu-system-x86_64 -smp 2 -m 4G -kernel kernel/linux/arch/x86_64/boot/bzImage
 -drive file=ubuntu-xenial.raw,index=0,media=disk,format=raw
 -drive file=disk1.raw,if=ide,index=1,cache=writeback,media=disk,format=raw
 -drive file=disk2.raw,if=ide,index=2,cache=writeback,media=disk,format=raw
 -drive file=disk3.raw,if=ide,index=3,cache=writeback,media=disk,format=raw
 -append "ip=dhcp root=/dev/sda console=ttyS0" -netdev user,id=user.0 -device
 e1000,netdev=user.0 -redir tcp:2222::22 --enable-kvm --nographic
