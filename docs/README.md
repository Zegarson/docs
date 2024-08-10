# Zegarson software docs

## Docker dev environment

For development purposes there is preconfigured docker container in the root directory of this repo. To use it type:

**Disclaimer:** due to EULA `st-stm32cubeide_1.16.0` cannot be included in this repo thus you need to download it manually from https://www.st.com/en/development-tools/stm32cubeide.html . You can also ignore the second image and only use zegarson-dev without STM32CubeIDE.

### Build

```sh
docker build -t zegarson-dev:latest -f Dockerfile.base .
docker build -t zegarson-cube32ide:latest -f Dockerfile.cube .
```

### Use

```sh
docker run -it \
    -e "DISPLAY" \
    -e "XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR" \
    -v "$XDG_RUNTIME_DIR:$XDG_RUNTIME_DIR" \
    -v "/tmp/.X11-unix:/tmp/.X11-unix" \
    -v "./:/home/dev/zegarson" \
    zegarson-cube32ide
```

## Boot chain

tf-a -> op-tee(optional security) -> u-boot -> linux kernel

## DTS

Every dts file is stored in https://github.com/Zegarson/dts . Repository has structure:

- cubeMX - clean auto generated dts files
- dtb - selected compiled dtb files for analysis
- generic - example dts pulled from different dev boards like DK2 or EV1
- ours - modified and tested cubeMX files which should be used for building OS

### Configured

- STM32MP157DAC - SOC
- 04EM04-N3GM627 - eMMC
- STPMIC1B - PMIC

### Not configured

- 04EM04-N3GM627 - LPDDR3
- MAX17330 - battery management + charger
- ED178AM368MS - amoled
- microphone - standard PDM
- speaker - D-class amp. I2S

### Problematic driver

- CYW43439 - WIFI/BT:
  - https://community.st.com/t5/stm32-mpus-products/support-for-murata-1yn-cyw43439-chipset/td-p/56761
- ED178AM368MS - amoled:
  - This driver just does not exist and needs to be written from scratch

## U-boot

### Bootstrap requirments

Currently u-boot needs to set up this hardware:

```md
Everything is supported in Linux but U-Boot is limited to the boot device:

1.  UART
2.  SD card/MMC controller (SDMMC)
3.  NAND controller (FMC)
4.  NOR controller (QSPI)
5.  USB controller (OTG DWC2)
6.  Ethernet controller

And the necessary drivers

1.  I2C
2.  STPMIC1 (PMIC and regulator)
3.  Clock, Reset, Sysreset
4.  Fuse (BSEC)
5.  OP-TEE
6.  ETH
7.  USB host
8.  WATCHDOG
9.  RNG
10. RTC
```

### Fetch source

```sh
git clone https://github.com/STMicroelectronics/u-boot.git
```

### Add DTS

```sh
git clone https://github.com/Zegarson/dts
ln ./dts/ours/u-boot/* ./u-boot/arch/arm/dts/
cd u-boot
```

You will also need to modify `./u-boot/arch/arm/dts/Makefile` to add `stm32mp157d-zegarson.dtb` to `dtb-$(CONFIG_STM32MP15X) +=` section.

### Build

In u-boot firmware directory:

```sh
export DEVICE_TREE=stm32mp157d-zegarson
export CROSS_COMPILE=arm-none-eabi-

rm -rf build
make stm32mp15_trusted_defconfig
make all
```

## arm-trusted-firmware

### Fetch source

```sh
git clone https://github.com/STMicroelectronics/arm-trusted-firmware.git
```

### Add DTS

```sh
git clone https://github.com/Zegarson/dts
ln ./dts/ours/tf-a/* ./arm-trusted-firmware/fdts/
cd arm-trusted-firmware
```

### Build

### Clean (optional)

```
make clean
make realclean
```

#### BL2

```sh
make CROSS_COMPILE=arm-none-eabi- PLAT=stm32mp1 ARCH=aarch32 ARM_ARCH_MAJOR=7 DEBUG=1 \
    DTB_FILE_NAME=stm32mp157d-zegarson.dtb STM32MP_SDMMC=1
```

#### BL32 (FIP old)

```sh
make CROSS_COMPILE=arm-none-eabi- PLAT=stm32mp1 ARCH=aarch32 ARM_ARCH_MAJOR=7 DEBUG=1 \
    AARCH32_SP=sp_min DTB_FILE_NAME=stm32mp157d-zegarson.dtb bl32 dtbs
```

## BL32 (optee-os)

### Fetch source

```sh
git clone https://github.com/STMicroelectronics/optee_os.git
```

### Add DTS

```sh
git clone https://github.com/Zegarson/dts
ln ./dts/ours/optee-os/* ./optee_os/core/arch/arm/dts/
cd optee_os
```

You will also need to modify `/optee_os/core/arch/arm/plat-stm32mp1/conf.mk`:

- Add this line `flavor_dts_file-157D_DK1 = stm32mp157d-dk1.dts` at the beginning of the file among the other mp157 boards.
- Add `$(flavor_dts_file-157D_ZEGARSON)` to `flavorlist-no_cryp-512M` and `flavorlist-MP15` lists

### Build

Rename binaries. I am not sure why but this step is required on Fedora 40 linux:

```sh
sudo dnf install python3-pyelftools
sudo ln -s /usr/bin/arm-none-eabi-gcc /usr/bin/arm-linux-gnueabihf-gcc
sudo ln -s /usr/bin/arm-none-eabi-objcopy /usr/bin/arm-linux-gnueabihf-objcopy
sudo ln -s /usr/bin/arm-none-eabi-cpp /usr/bin/arm-linux-gnueabihf-cpp
sudo ln -s /usr/bin/arm-none-eabi-ar /usr/bin/arm-linux-gnueabihf-ar
sudo ln -s /usr/bin/arm-none-eabi-ld /usr/bin/arm-linux-gnueabihf-ld
sudo ln -s /usr/bin/arm-none-eabi-ld.bfd /usr/bin/arm-linux-gnueabihf-ld.bfd
sudo ln -s /usr/bin/arm-none-eabi-objdump /usr/bin/arm-linux-gnueabihf-objdump
sudo ln -s /usr/bin/arm-none-eabi-nm /usr/bin/arm-linux-gnueabihf-nm
```

```sh
make CROSS_COMPILE=arm-linux-gnueabihf- ARCH=arm PLATFORM=stm32mp1 DEBUG=1 \
    CFG_TEE_CORE_LOG_LEVEL=4 \
    CFG_EMBED_DTB_SOURCE_FILE=stm32mp157d-zegarson.dts
```

## Generating FIP image bundle

In arm-trusted firmware directory:

```sh
cd arm-trusted-firmware

export DEVICE_TREE=stm32mp157d-zegarson
export CROSS_COMPILE=arm-none-eabi-
```

### SP_MIN fip

```sh
make CROSS_COMPILE=arm-none-eabi- DEBUG=1 EARLY_CONSOLE=1 \
    PLAT=stm32mp1 ARCH=aarch32 ARM_ARCH_MAJOR=7 \
    AARCH32_SP=sp_min \
    DTB_FILE_NAME=stm32mp157d-zegarson.dtb \
    BL33=../u-boot/u-boot-nodtb.bin \
    BL33_CFG=../u-boot/u-boot.dtb \
    fip
```

### OPTEE-OS fip

```sh
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

### Resulting files

**Resulting files will be located in**:

- `arm-trusted-firmware/build/stm32mp1/debug/fip.bin`
- `arm-trusted-firmware/build/stm32mp1/debug/tf-a-stm32mp157d-zegarson.stm32`

## Scripts

If you complete build of `tf-a, u-boot and FIP` once you can modify shell script included in this repo (`scripts/build_fip_sh`) to automate this process for later builds.

## Flashing SD card:

**Disclaimer:** Before proceding with this step check the device path using `lsblk` or `cat /proc/partitions` commands. If you select wrong device you can overwrite existing data on your computer or render it unbootalbe.

**Tip:** If you are working on windows 10 or 11 you can use MSYS2 to provide needed linux commands without installing whole linux VM.

### Create new GPT partition table

```sh
sgdisk
sgdisk -o /dev/sdb
```

### Create required partitions

```sh
sgdisk --resize-table=128 -a 1 \
-n 1:34:545         -c 1:fsbl1 \
-n 2:546:1057               -c 2:fsbl2 \
-n 3:1058:9249              -c 3:fip \
-n 4:9250:                  -c 4:rootfs -A 4:set:2 \
-p /dev/sdb
```

### Copy binaries onto the card

```sh
dd if=tf-a.stm32 of=/dev/sdb1
dd if=tf-a.stm32 of=/dev/sdb2
dd if=fip.bin of=/dev/sdb3
```

## OpenSTLinux (broken)

SDK: https://www.st.com/en/embedded-software/stm32mp1dev.html#get-software

```sh
mkdir st-yocto
cd st-yocto
repo init -u https://github.com/STMicroelectronics/oe-manifest.git -b refs/tags/openstlinux-6.1-yocto-mickledore-mpu-v24.06.26
repo sync
DISTRO=openstlinux-core MACHINE=stm32mp1 source layers/meta-st/scripts/envsetup.sh
bitbake st-image-core
```

## Yocto build (broken)

This instruction is for yocto I have not yet played around with openst linux due to lack of linux environment.

Disclaimer **Run this inside of dev-container as it creates huge mess of the file-system which is unmanageable manually**

```sh
sudo chown dev:dev /data
cd /data
mkdir yocto-labs
cd yocto-labs
git clone git://git.yoctoproject.org/poky.git
cd poky
git checkout -b dunfell-23.0.32 dunfell-23.0.32
cd ..
```

Add STM32 specific layers:

```sh
cd /data/yocto-labs
git clone -b dunfell git://git.openembedded.org/meta-openembedded
git clone -b dunfell https://github.com/STMicroelectronics/meta-st-stm32mp.git
```

Set env vars:

```sh
cd /data/yocto-labs/
source poky/oe-init-build-env
```

Add this bblayers to `/data/build/conf/bblayers.conf`:

```sh
BBLAYERS ?= " \
    /data/yocto-labs/poky/meta \
    /data/yocto-labs/poky/meta-poky \
    /data/yocto-labs/poky/meta-yocto-bsp \
    /data/yocto-labs/meta-openembedded/meta-oe \
	  /data/yocto-labs/meta-openembedded/meta-python \
    /data/yocto-labs/meta-st-stm32mp \
    "
```

Build (if you want a desktop environment change core-image-minimal to other valid type with weston included):

```sh
cd /data/yocto-labs/build
MACHINE=stm32mp1 bitbake core-image-minimal
```

Build flashable image

```sh
cd /data/yocto-labs/build/tmp/deploy/images/stm32mp1/scripts
./create_sdcard_from_flashlayout.sh ../flashlayout_core-image-minimal/extensible/FlashLayout_sdcard_stm32mp157f-dk2-extensible.tsv
```

### Modifications using yocto

If you want to apply any modification on the system using yocto just eneter into the linux directory create commit, and export it as git path with an extension of .path. Yocto can use these files to automatically build modified distros.

## LVGL

- https://lvgl.io/
- https://docs.lvgl.io/8.2/get-started/pc-simulator.html

How to run this on top of linux without an simulaor?

## Display

Create linux patch for https://github.com/torvalds/linux/blob/master/drivers/gpu/drm/panel/panel-simple.c and add to yocto

- https://www.linux.org/threads/panel-simple-c-display-driver-clarification.45673/

## WIFI-card

TODO

## JTAG/SWD

### Tools

- https://github.com/raspberrypi/debugprobe
- https://github.com/kholia/xvc-pico/tree/ng (not sure if it works with non xilix devices?)
- https://openocd.org/
- https://www.onlinegdb.com/

### Pico debug probe

To install debug probe flash this two files to pico:

- flash_nuke.uf2
  - https://github.com/dwelch67/raspberrypi-pico/blob/main/flash_nuke.uf2
- debugprobe_on_pico.uf2
  - https://github.com/raspberrypi/debugprobe/releases
  - If you are using pico-W you will need to recompile the debug probe from source with certain patches

### Using openocd

```sh
openocd -f interface/cmsis-dap.cfg -f target/stm32mp15x.cfg
telnet localhost 4444
```

### Example commands

- `halt`
- `resume`
- `reg`
- `flash probe 0`

## TODO:

- Display
- DTS\*
- WiFi
- Emulator:
  - Probably we should use x86 qemu based emulator built into yocto or raspi3 board as a base (testing apps and builds not drivers)
- LVGL / QT / GTK - Decide how we want to use linux?
- OpenStLinux build + dev env based of ubuntu, main dockerfile could partially work, but I have not tested that
