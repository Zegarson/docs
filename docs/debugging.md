# Debugging

## SWD

### Tools

For debugging using JTAG/SWD, you can use the following tools:

- **[Raspberry Pi Debug Probe](https://github.com/raspberrypi/debugprobe)**: A hardware probe for debugging with Raspberry Pi.
- **[XVC Pico](https://github.com/kholia/xvc-pico/tree/ng)**: A tool for interfacing with Xilinx devices. (Note: It may not work with non-Xilinx devices.)
- **[OpenOCD](https://openocd.org/)**: Open On-Chip Debugger, a free and open-source tool for debugging and programming.
- **[OnlineGDB](https://www.onlinegdb.com/)**: An online compiler and debugger with support for various programming languages and debugging tools.

### Wrap Your Image

To enable debugging of STM32MP1 software, you need to add a debug wrapper to your FSBL (First Stage Boot Loader) image with a `.stm32` extension. Follow these steps to prepare your image for debugging:

1. **Download and Build the Wrapper Tool**

First, clone the STM32 debug wrapper repository and build the tool:

```sh
git clone https://github.com/STMicroelectronics/stm32wrapper4dbg.git
cd stm32wrapper4dbg
make
```

This will compile the `stm32wrapper4dbg` tool.

2. **Install the Wrapper Tool**

Copy the compiled `stm32wrapper4dbg` executable and its man page to a directory in your system's PATH. This allows you to access the command from anywhere on your system. For example:

```sh
sudo cp stm32wrapper4dbg /usr/local/bin/
sudo cp stm32wrapper4dbg.1 /usr/local/share/man/man1/
```

Ensure the installation directories (`/usr/local/bin/` and `/usr/local/share/man/man1/`) are included in your PATH and MANPATH environment variables.

3. **Wrap Your FSBL Image**

Use the `stm32wrapper4dbg` tool to add the debug wrapper to your FSBL image. Run the following command:

```sh
stm32wrapper4dbg -s <your_FSBL>.stm32 -d wrapped.stm32
```

Replace `<your_FSBL>.stm32` with the path to your original FSBL image file. This command creates a new file named `wrapped.stm32` that includes the debug wrapper.

4. **Flash the Wrapped Image**

Flash the `wrapped.stm32` image onto your Zegarson board. After booting, the board will wait for 2 seconds to establish a connection over the SWD (Serial Wire Debug) interface.

### Install Debug Probe on Raspberry Pi Pico

To install the Debug Probe on a Raspberry Pi Pico, flash the following files:

1. **`flash_nuke.uf2`**: This file is used to clear the Pico's flash memory. You can download it from:

   - [flash_nuke.uf2](https://github.com/dwelch67/raspberrypi-pico/blob/main/flash_nuke.uf2)

2. **`debugprobe_on_pico.uf2`**: This file sets up the Pico as a Debug Probe. Download it from:
   - [debugprobe_on_pico.uf2](https://github.com/raspberrypi/debugprobe/releases)
   - **Note:** If you are using a Pico-W, you may need to recompile the Debug Probe from source with specific patches to ensure compatibility.

### Start OpenOCD Server

To start the OpenOCD server, use the following command:

```sh
openocd -f interface/cmsis-dap.cfg -f target/stm32mp15x.cfg -c "adapter speed 1000" -c "set _timeout 1000" -c "init; halt"
```

This command configures OpenOCD with the CMSIS-DAP interface and the STM32MP15x target configuration, sets the adapter speed, and initializes and halts the target device.

### Connect Using GDB

To connect to the OpenOCD server using GDB, run:

```sh
gdb
(gdb) target extended-remote localhost:3333
```

This command connects GDB to the OpenOCD server running on `localhost` at port `3333`.

### Example Commands

Once connected to GDB, you can use the following commands for debugging:

- **Set a breakpoint**: `b <addr>`
  - Sets a breakpoint at the specified address.
- **Set a hardware breakpoint**: `hb <addr>`
  - Sets a hardware breakpoint at the specified address.
- **Display variable values**: `set <variable> = <value>`
  - Sets the value of a variable.
- **Probe connected flash**: `flash probe 0`
  - Probes for connected flash devices.
- **Examine memory**: `x/1xw <addr>`
  - Examines memory at the specified address, showing one word in hexadecimal format.

These commands allow you to control and inspect the state of your target device during debugging.
