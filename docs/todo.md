# To be done

## List

- [ ] Display
- [x] DTS
- [x] WiFi
- [ ] LVGL / QT / GTK - Decide how we want to use linux?
- [ ] USB tusb320
- [ ] low power states
- [x] Fully working qemu build based of ~~arm-versatile~~ x86_64
- [ ] AB updates using rauc
- [x] SSH using dropbear
- [x] GPU drivers
  - [ ] Etnaviv to GcNano
- [x] Fix caching using CCACHE + PER_PACKAGE flag
- [ ] M4 coprocessor
- [ ] Bluetooth
- [ ] Stabilize boot
- [x] Alpine

## LVGL

Even that there are many more powerful linux compatible GUI libraries LVGL will allow for unified UI across A7 and M4 cores.

- https://lvgl.io/
- https://docs.lvgl.io/8.2/get-started/pc-simulator.html

LVGL under linux:

- https://wiki.luckfox.com/Luckfox-Pico/Luckfox-Pico-LVGL

## Display

- Create linux patch for https://github.com/torvalds/linux/blob/master/drivers/gpu/drm/panel/panel-simple.c
- https://www.linux.org/threads/panel-simple-c-display-driver-clarification.45673/
