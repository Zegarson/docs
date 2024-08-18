# To be done

## List

- [ ] Display
- [x] DTS
- [ ] WiFi
- [ ] LVGL / QT / GTK - Decide how we want to use linux?
- [ ] USB tusb320
- [ ] low power states
- [ ] Fully working qemu build based of arm-versatile
- [ ] AB updates using rauc
- [ ] SSH using dropbear
- [ ] GPU drivers (disable etnaviv)
- [ ] Fix caching using CCACHE + PER_PACKAGE flag

## LVGL

- https://lvgl.io/
- https://docs.lvgl.io/8.2/get-started/pc-simulator.html

How to run this on top of linux without an simulaor?

## Display

Create linux patch for https://github.com/torvalds/linux/blob/master/drivers/gpu/drm/panel/panel-simple.c and add to yocto

- https://www.linux.org/threads/panel-simple-c-display-driver-clarification.45673/
