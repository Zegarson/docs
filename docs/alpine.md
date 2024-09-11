# Alpine Root Filesystem

## Rationale

To improve the development experience, we decided to repurpose an Alpine Linux root filesystem from a Docker container as the foundation for our basic distribution. This approach allows us to leverage Alpine’s extensive ecosystem, which includes many useful tools like `gcc`, `g++`, `make`, and other utilities that would be challenging to port to our board. By using Alpine, we also benefit from a well-established set of packages and updates while keeping the system lightweight.

## Building the Root Filesystem

**Note:** This process has already been automated using Buildroot, so the following steps serve more as a reference or debugging guide rather than a strict requirement.

Currently, we use Docker to build the Alpine root filesystem due to its simplicity and flexibility. While we plan to migrate to a setup involving QEMU and `chroot`, Docker is still a necessary dependency for now. Since we are working with non-x86 architectures, we need to ensure our host can handle instruction mismatches. For this, we use `qemu-user-static`, which allows us to run containers using any architecture supported by QEMU system emulation.

To enable this feature, run the following command:

```sh
docker run --rm --privileged multiarch/qemu-user-static --reset --persistent yes
```

### Docker Images by Architecture

- ARMv6 32-bit: [arm32v6](https://hub.docker.com/u/arm32v6/)
- ARMv7 32-bit: [arm32v7](https://hub.docker.com/u/arm32v7/)
- ARMv8 64-bit: [arm64v8](https://hub.docker.com/u/arm64v8/)
- Linux x86-64: [amd64](https://hub.docker.com/u/amd64/)

For example, to create an Alpine root filesystem for ARMv7, use the following command:

```sh
docker run -it -v /tmp/alpine-rootfs/arm32v7:/alpine-rootfs arm32v7/alpine
```

### Making the Root Filesystem Bootable

The Alpine root filesystem is initially designed for containers, meaning it doesn’t have OpenRC services enabled by default. To make the image bootable and set up useful features, follow these steps:

1. **Update packages:**

   ```sh
   apk update
   ```

2. **Enable essential services:**

   ```sh
   apk add alpine-base openrc
   rc-update add devfs boot
   rc-update add procfs boot
   rc-update add sysfs boot
   ```

3. **Change the default shell:**

   ```sh
   apk add agetty shadow bash
   chsh -s /bin/bash root
   ```

4. **Configure networking:**

   ```sh
   apk add wpa_supplicant
   rc-update add networking default
   ```

5. **Set up SSH:**

   ```sh
   apk add openssh
   rc-update add sshd default
   ```

6. **Set up timezone:**

   ```sh
   rc-update add local default
   apk add tzdata
   ```

7. **Install firmware (for specific hardware like Broadcom):**

   ```sh
   apk add linux-firmware-brcm libdrm
   ```

8. **Install additional utilities:**

   ```sh
   apk add util-linux nano neofetch git
   ```

### Exporting Files for Buildroot

Once the root filesystem is prepared, export all necessary files back to `/tmp/alpine-rootfs/$ALPINE_ARCH` so that Buildroot can use them:

```sh
for d in bin etc lib root sbin usr; do tar c "$d" | tar x -C /alpine-rootfs; done
for dir in dev proc run sys var; do mkdir /alpine-rootfs/${dir}; done
```

### Fixing Permissions

Finally, ensure proper permissions on the exported files:

```sh
sudo chmod 755 /tmp/alpine-rootfs/$ALPINE_ARCH
```

After these steps, you can place the prepared root filesystem into the `target` directory of Buildroot to achieve the same effect as the automated recipe.
