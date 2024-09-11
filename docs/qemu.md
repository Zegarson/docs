# QEMU Setup

## x86_64 Virtual Machine

With our Buildroot recipe now supporting multiple boards, you can test applications and the entire root filesystem within a QEMU virtual machine. For performance reasons, QEMU targets `x86_64` instead of the more appropriate `armv7`. Using the `-kvm` feature allows Linux to leverage hardware virtualization, which results in significantly faster performance—making debugging much smoother.

### Important Note:

This setup only emulates the user space; QEMU does not simulate U-Boot or OP-TEE. As a result, any errors related to bootloaders or secure environments will not be detected during these tests.

### Running the Virtual Machine

First, build your root filesystem using the `qemu_x86_64_alpine_defconfig` configuration in Buildroot. Once the build is complete, you can run the virtual machine with the following command:

```sh
qemu-system-x86_64 -M pc -kernel qemu_x86_64/images/bzImage \
-drive file=qemu_x86_64/images/rootfs.ext4,if=virtio,format=raw \
-append "root=/dev/vda rootdelay=3 rootwait console=tty1 console=ttyS0" \
-serial stdio -net nic,model=virtio -net user -enable-kvm
```

This will boot the system with the virtual root filesystem and the QEMU virtual machine in a more performant manner using KVM acceleration.
