# Development Environment Setup

## Windows

Building on Windows requires a compatibility layer to simulate a native Linux environment. While MSYS2 can provide essential tools like `make` and `dd`, it is insufficient for completing the full Buildroot build. To properly run Buildroot, install either **WSL2** or set up a **VirtualBox** environment with **Ubuntu 22.04** or newer. This environment will be suitable for the entire development process.

Once your environment is set up, follow the Linux build instructions and ensure Docker is installed. Docker is needed for generating the Linux root filesystem. While it's theoretically possible to use only Docker with the provided `Dockerfile` in Docker Desktop, this approach is untested.

### USB Device Access in WSL2

Many Zegarson-related commands require access to USB devices like JTAG debuggers and UART probes. Windows isolates USB devices by default, so you’ll need to use the [wsl-usb-gui tool](https://gitlab.com/alelec/wsl-usb-gui) to pass through USB devices to WSL2. However, USB storage is disabled in WSL2 by default. To access USB drives or SD cards, you will need to build a custom kernel with `USB_STORAGE=y` enabled. After applying this modification, USB storage devices should function correctly within the WSL2 environment.

## Native Linux Setup

You can use various up-to-date Linux distributions to build both the OS and flashing utilities. Tested environments include **Fedora 40** and **Ubuntu 20.04**. The current Buildroot configuration, based on Alpine Linux, requires Docker as a dependency. It’s essential to use Docker (not Podman), as the build process relies on `docker run` with the `--privileged` flag, which is incompatible with Podman’s rootless setup.

For Ubuntu users, you can install most required dependencies using the following command:

```sh
# Buildroot dependencies
sudo apt install sed make debianutils binutils build-essential diffutils gcc g++ patch gzip bzip2 perl tar cpio unzip rsync file bc findutils python3 libssl-dev

# Development tools and utilities
sudo apt install sudo wget curl neofetch git bash nano locales ca-certificates
```

To install docker just follow [Official Documentation](https://docs.docker.com/engine/install/ubuntu/)

For additional details, refer to the [Buildroot Prerequisites](https://buildroot.org/downloads/manual/prerequisite.txt) documentation.

## Docker as a Development Environment

In addition to generating the Alpine root filesystem, Docker can be used as an isolated build environment. To set up Docker for development, first clone the `buildroot-external` repository and navigate to its main directory:

```sh
git clone https://github.com/Zegarson/buildroot-external.git
cd buildroot-external
```

You’ll find two important files in this directory:

- **Dockerfile**: A recipe for an **Ubuntu 20.04**-based environment with all necessary dependencies, including Docker CLI.
- **compose.yml**: This file defines how to run the environment and mount necessary files. You may need to tweak default paths in `compose.yml` to match your system's directory structure.

To build and enter the Docker environment, run the following commands:

```sh
docker-compose build
docker-compose up -d
docker-compose exec ubuntu-buildroot bash
```

After running the last command, you’ll be inside a partially isolated development environment. When you're finished, exit the shell and shut down the environment by running:

```sh
docker-compose down
```
