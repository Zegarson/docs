# Zegarson software docs

## Docker dev enviorment

For development purposes there is preconfigured docker container in the root directory of this repo. To use it type:

```sh
docker build -t zegarson-dev .
docker run -dit -P --name yocto -v ./data:/data:z  zegarson-dev
```

## Boot chain

tf-a -> op-tee(optional security) -> u-boot -> linux kernel

## Yocto build

This instruction is for yocto I have not yet played around with openst linux due to lack of linux enviorment.

Disclaimer **Run this inside of dev-container as it creates huge mess of the file-system which is unmagable manually**

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

Build (if you want a desktop enviorment change core-image-minimal to other valid type with weston included):

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

If you want to apply any modifaction on the system using yocto just eneter into the linux directory create commit, and export it as git path with an extension of .path. Yocto can use these files to automaticlly build modified distros.

## DTS

It is what it is

### Configured

- STM32MP157DAC - SOC
- 04EM04-N3GM627 - LPDDR3 + eMMC
- STPMIC1B - PMIC (needs verification)

### Not configured

- MAX17330 - battery management + charger
- ED178AM368MS - amoled
- microphone - standard PDM
- speaker - D-class amp. I2S

### Problematic driver

- CYW43439 - WIFI/BT:
  - https://community.st.com/t5/stm32-mpus-products/support-for-murata-1yn-cyw43439-chipset/td-p/56761
- ED178AM368MS - amoled:
  - This driver just does not exist and needs to be written from scratch

## U-Boot

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

## LVGL

- https://lvgl.io/
- https://docs.lvgl.io/8.2/get-started/pc-simulator.html

How to run this on top of linux without an simulaor?

## Display

Create linux patch for https://github.com/torvalds/linux/blob/master/drivers/gpu/drm/panel/panel-simple.c and add to yocto

- https://www.linux.org/threads/panel-simple-c-display-driver-clarification.45673/

## WIFI-card

## JTAG/SWD

I will later add this tools to docker file and document how to fully utilize them:

Tools:

- https://github.com/raspberrypi/debugprobe
- https://github.com/kholia/xvc-pico/tree/ng (not sure if it works with non xilix devices?)
- https://openocd.org/
- https://www.onlinegdb.com/

## TODO:

- Display
- DTS\*
- WiFi
- Emulator:
  - Probably we should use x86 qemu based emulator built into yocto or raspi3 board as a base (testing apps and builds not drivers)
- LVGL / QT / GTK - Decide how we want to use linux?
- OpenStLinux build + dev env based of ubuntu, main dockerfile could partially work, but I have not tested that
