export DEVICE_TREE=stm32mp157d-zegarson
export CROSS_COMPILE=arm-none-eabi-
export LOG_LEVEL=40

cd /home/frankoslaw/Documents/programming/projects/zegarson/u-boot

rm -rf build
make stm32mp15_trusted_defconfig
make all

cd /home/frankoslaw/Documents/programming/projects/zegarson/arm-trusted-firmware

make CROSS_COMPILE=arm-none-eabi- PLAT=stm32mp1 ARCH=aarch32 ARM_ARCH_MAJOR=7 \
    AARCH32_SP=sp_min DTB_FILE_NAME=stm32mp157d-zegarson.dtb bl32 dtbs

make CROSS_COMPILE=arm-none-eabi- PLAT=stm32mp1 ARCH=aarch32 ARM_ARCH_MAJOR=7 \
    DTB_FILE_NAME=stm32mp157d-zegarson.dtb STM32MP_SDMMC=1

make CROSS_COMPILE=arm-none-eabi- LOG_LEVEL=40 DEBUG=1 EARLY_CONSOLE=1 PLAT=stm32mp1 ARCH=aarch32 ARM_ARCH_MAJOR=7 \
    AARCH32_SP=sp_min \
    DTB_FILE_NAME=stm32mp157d-zegarson.dtb \
    BL33=../u-boot/u-boot-nodtb.bin \
    BL33_CFG=../u-boot/u-boot.dtb \
    fip