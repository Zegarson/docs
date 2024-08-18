# Dev enviorment

## Windows

Building on Windows can be problematic. You can use MSYS2 to provide `make`, `dd`, and other utilities, but there is no guarantee that all commands will work correctly. Even if a command runs on Windows, due to various differences and patches, it may produce different results and break the build. It is highly advisable to use either WSL2 or VirtualBox when working on Windows.

**Disclaimer:** Many of the commands related to Zegarson rely on USB access. By default, Windows isolates USB access from the WSL2 virtual machine. To pass through USB devices, you can use the [wsl-usb-gui tool](https://gitlab.com/alelec/wsl-usb-gui). This will allow devices like JTAG debuggers and UART probes to work out of the box. However, due to the fact that Windows isolates USB by default, Microsoft has disabled USB storage in WSL2. As a result, you will need to build a custom kernel with `USB_STORAGE=y` enabled. After this modification, you should be able to access USB sticks and SD cards from inside the VM.

## Native linux

You can use many up-to-date Linux distributions to build both the OS and the utilities for flashing. The currently tested environments include Fedora 40 and Ubuntu 20.04. If you're not using Yocto, it is perfectly fine to install dependencies directly on your host machine. However, for Yocto builds, you will need Ubuntu 20.04 with a specific list of dependencies, so using a virtual machine or Docker container is recommended.

## Docker

For development purposes, there is a preconfigured Docker container in the root directory of this repo. To use it, follow the steps below:

**Disclaimer:** Due to the End User License Agreement (EULA), the `st-stm32cubeide_1.16.0` software cannot be included in this repo. You need to download it manually from [STMicroelectronics STM32CubeIDE](https://www.st.com/en/development-tools/stm32cubeide.html). Alternatively, you can ignore the second image and only use the `zegarson-dev` container without STM32CubeIDE.

### Build

```sh
docker build -t zegarson-dev:latest -f Dockerfile.base .
docker build -t zegarson-cube32ide:latest -f Dockerfile.cube .
```

### Usage

```sh
docker run -it \
    -e "DISPLAY" \
    -e "XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR" \
    -v "$XDG_RUNTIME_DIR:$XDG_RUNTIME_DIR" \
    -v "/tmp/.X11-unix:/tmp/.X11-unix" \
    -v "./:/home/dev/zegarson" \
    zegarson-cube32ide
```

### Notes:

- Ensure that the STM32CubeIDE is properly installed on your system before running the `zegarson-cube32ide` container.
- The `$(pwd)` command dynamically links the current directory to the container.
