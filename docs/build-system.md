# Linux build systems

## Buildroot

### Fetch source

To perform a Buildroot build, you will need to fetch two repositories: `buildroot` and `buildroot-external`. The first repository contains recipes to bootstrap the environment, build components like the Linux kernel, and orchestrate the entire build process. The second repository contains the specific configurations needed to build the Zegarson OS. This approach is preferred as it does not modify any Buildroot files, making it easier to update the base in the future:

```sh
git clone -b st/2024.02.3 https://github.com/bootlin/buildroot.git
git clone https://github.com/Zegarson/buildroot-external.git

cd buildroot-external
git submodule update --init
```

**Disclaimer:** The branch and the fact that Buildroot is fetched from Bootlin's sources are intentional. The vanilla Buildroot does not contain certain patches required to support GPU, OP-TEE, M4, and a few other peripherals. You can read more about this at the end of Bootlin's Buildroot-external-ST documentation: [Bootlin Buildroot-external-ST docs](https://github.com/bootlin/buildroot-external-st/blob/2f77318b449861183975be010431682092e2b0eb/docs/internals.md).

### Build

To build with Buildroot, you first need to install the necessary dependencies. The following command installs them on Ubuntu 20.04:

```sh
sudo apt install debianutils sed make binutils build-essential gcc g++ bash patch gzip bzip2 perl tar cpio unzip rsync file bc git
```

After installing the dependencies, navigate to the `buildroot` folder, specify the `buildroot-external` path, and initialize the build. You can select one of the three targets currently supported by the Zegarson project:

- `qemu_arm_versatile_defconfig` (unstable)
- `stm32mp157d_zegarson_defconfig`
- `stm32mp157d_zegarson_mini_defconfig`

```sh
cd buildroot
make BR2_EXTERNAL=../buildroot-external stm32mp157d_zegarson_mini_defconfig
```

This command will generate the configuration files for the build. If you wish, you can modify them using `menuconfig`. Finally, execute the `make` command to start the build:

```sh
make
```

Due to the size of the Buildroot project, the build will take around 30-40 minutes, depending on your hardware and internet speed. This process takes longer because the current configuration does not use CCACHE or multithreading, due to issues with stability and consistency. All the files needed for the flashing steps will be located in the `buildroot/output/images` folder.

If you want to build everything from scratch, run `make clean`. If you want to rebuild only a specific component, remove the appropriate folder from the `/buildroot/output/build/` directory. Since Buildroot does not reliably implement change detection, you will need to do this every time you modify files like DTS or overlays.

## Yocto

Currently, all builds are done using Buildroot due to its ease of modification. Although Buildroot is not officially supported by ST, it works well enough to be used for current releases. Yocto support is planned for future builds once the Linux configurations and DTS files have matured.

## Manual

### Fetch source

For testing and debugging purposes, you may want to build all the components manually. While this is generally discouraged, as Buildroot can perform the entire process for you, the option still exists. Before you begin, you will need to clone the Device Tree Source (DTS) files as well as the source code for each component. Keep in mind that each component is fetched with a specific version from ST's repositories, and changing this may lead to a broken build:

```sh
git clone https://github.com/Zegarson/dts
git clone https://github.com/STMicroelectronics/arm-trusted-firmware.git
git clone https://github.com/STMicroelectronics/optee_os.git
git clone https://github.com/STMicroelectronics/u-boot.git
```

Next, you will need to set up all the symlinks to the correct DTS files for each project. This can be achieved with the following commands:

```sh
ln ./dts/ours/tf-a/* ./arm-trusted-firmware/fdts/
ln ./dts/ours/optee-os/* ./optee_os/core/arch/arm/dts/
ln ./dts/ours/u-boot/* ./u-boot/arch/arm/dts/
```

If these files already exist or the symlinks are broken, you can remove the existing DTS files before creating new symlinks with the following commands:

```sh
rm ./arm-trusted-firmware/fdts/stm32mp157d-zegarson.dts
rm ./arm-trusted-firmware/fdts/stm32mp157d-zegarson-fw-config.dts
rm ./arm-trusted-firmware/fdts/stm32mp15-mx.dtsi
rm ./optee_os/core/arch/arm/dts/stm32mp157d-zegarson.dts
rm ./u-boot/arch/arm/dts/stm32mp157d-zegarson.dts
rm ./u-boot/arch/arm/dts/stm32mp157d-zegarson-scmi.dtsi
rm ./u-boot/arch/arm/dts/stm32mp157d-zegarson-u-boot.dtsi
```

Since this is a completely manual build, OP-TEE and U-Boot will not automatically recognize these DTS files. To fix this, you will need to make the following modifications in the appropriate folders:

1. You need to modify `/optee_os/core/arch/arm/plat-stm32mp1/conf.mk`:

   - Add this line `flavor_dts_file-157D_ZEGARSON = stm32mp157d-zegarson.dts` at the beginning of the file among the other mp157 boards.
   - Add `$(flavor_dts_file-157D_ZEGARSON)` to `flavorlist-no_cryp-512M` and `flavorlist-MP15` lists

2. You will also need to modify `/u-boot/arch/arm/dts/Makefile` to add `stm32mp157d-zegarson.dtb` to `dtb-$(CONFIG_STM32MP15X) +=` section.

You are now ready to build.

### Build

#### Build BL2 (Arm Trusted Firmware)

Before starting the build process, you may want to perform a clean build by removing any previous build artifacts. This ensures that the build environment is fresh and prevents issues caused by leftover files. You can use the following commands to clean the build:

```sh
make clean
make realclean
```

BL2 is the second stage bootloader in Arm Trusted Firmware (ATF). To build BL2 for the STM32MP1 platform with your custom DTS, follow these steps:

```sh
cd arm-trusted-firmware
make CROSS_COMPILE=arm-none-eabi- PLAT=stm32mp1 ARCH=aarch32 ARM_ARCH_MAJOR=7 DEBUG=1 \
    DTB_FILE_NAME=stm32mp157d-zegarson.dtb STM32MP_SDMMC=1
```

#### Build OP-TEE OS

OP-TEE (Trusted Execution Environment) provides a secure environment for the execution of trusted code.

```sh
make CROSS_COMPILE=arm-none-eabi- ARCH=arm PLATFORM=stm32mp1 DEBUG=1 \
    CFG_TEE_CORE_LOG_LEVEL=3 \
    CFG_EMBED_DTB_SOURCE_FILE=stm32mp157d-zegarson.dts
```

#### U-boot

U-Boot is a popular bootloader that provides a versatile environment for booting Linux and other operating systems. To build U-Boot for the STM32MP1 platform with your custom Device Tree, follow these steps:

1. Optionally, perform a clean build by removing the `build` directory:

```sh
rm -rf build
```

2. Navigate to the `u-boot` directory.

```sh
cd u-boot
```

3. Export the necessary environment variables to specify the custom Device Tree and the cross-compiler:

```sh
export DEVICE_TREE=stm32mp157d-zegarson
export CROSS_COMPILE=arm-none-eabi-
```

4. Use the following make commands to configure and build U-Boot:

```sh
make stm32mp15_defconfig
make all
```

### FIP

Finally, to be able to flash all of these components, you will need to create a FIP (Firmware Image Package) bundle. This can be done using the following command:

```sh
cd arm-trusted-firmware
make CROSS_COMPILE=arm-none-eabi- DEBUG=1 EARLY_CONSOLE=1 \
    PLAT=stm32mp1 ARCH=aarch32 ARM_ARCH_MAJOR=7 \
    AARCH32_SP=optee \
    DTB_FILE_NAME=stm32mp157d-zegarson.dtb \
    BL33=../u-boot/u-boot-nodtb.bin \
    BL33_CFG=../u-boot/u-boot.dtb \
    BL32=../optee_os/out/arm-plat-stm32mp1/core/tee-header_v2.bin \
    BL32_EXTRA1=../optee_os/out/arm-plat-stm32mp1/core/tee-pager_v2.bin \
    BL32_EXTRA2=../optee_os/out/arm-plat-stm32mp1/core/tee-pageable_v2.bin \
    fip
```

This command assembles the FIP bundle, which includes various components like U-Boot (BL33) and OP-TEE (BL32), along with the necessary Device Tree (DTS) file and configuration.

#### Resulting files

The resulting files will be located in the following directories:

- `arm-trusted-firmware/build/stm32mp1/debug/fip.bin`
- `arm-trusted-firmware/build/stm32mp1/debug/tf-a-stm32mp157d-zegarson.stm32`

These files are the final output and are used to flash the firmware onto your target device.
