# Simple Z80 Computer
The goal of this project was to build a minimally complex Z80 computer capable of running CP/M. While I haven not yet ported CP/M, it should be capable of it.

This system is made of two boards, the upper board has the the CPU, RAM, ROM and UART. The lower board has Composite Video, USB Keyboard, USB to serial converter, Compact Flash and 8 indicator LEDs.

If you want to have a better understanding of how this system works you checkout the schematics or my [blog](https://blog.tephra.me/z80_sbc/).

![Screenshot](images/simple_Z80_system.jpg)


## Specifications ##
* 64K Static RAM
* 32K ROM
* Z80 @ 4Mhz
* USB Keyboard via Raspberry Pi Zero
* Composite Video via Raspberry Pi Zero
* HDMI Video via Raspberry Pi Zero
* Support for 27256 or AT28C256 ROM
* Compact Flash
* 8 LED indicators
* Built in USB to serial converter @ 9600 baud

## Raspberry Pi Zero (Optional) ##
As part of the project I wanted to have a composite video output however there was not sufficient space to have a native composite video interface. As an alternative I have used a Raspberry Pi Zero running [pigfx](https://github.com/fbergama/pigfx) which acts as a terminal emulator providing a USB keyboard input and composite video output.

### Raspberry Pi Installation ###
To the under side of the PCB solder in the Raspberry Pi using the pins from a 2.54mm header so that the Pi is flat against the PCB. Only the circles and yellow need to be soldered. Back on the top side of the PCB you will see some pads the need to be connected to some test points on the Pi, connect them using some wire off cuts.

![Screenshot](images/raspberry_pi_solder_points.png)

## ROM Jumper Configuration ##

This system supports the W27C257, 27256 and AT28C256 ROM chips. The W27C257, 27256 are read only and need to have to jumpers set in the top most position. The AT28C256 is read/write and need two jumpers in the lower position.

![Screenshot](images/rom_jumper_setting.jpg)

## Software Compiler ##
My assembler of choice for this project has been the [Retro Assembler](https://enginedesigns.net/retroassembler/) by Peter Tihanyi. There is a VSCode [plugin](https://marketplace.visualstudio.com/items?itemName=EngineDesigns.retroassembler) available.

## Memory Address Space ##

This system has 64K of RAM and 32K of ROM. However, the Z80 can only ever address 64K at a time. When the system starts up the top 32K of memory maps to RAM, and the lower 32K maps to ROM. The system can, when ready, swap the lower 32K of ROM for RAM.

![Screenshot](images/memory_layout.png)

 ## IO Address Space ##

| Address | Device        | R/W | Description             |
|---------|---------------|-----|-------------------------|
| 0x10    | SIO           | R/W | UART A Data Register    |
| 0x11    | SIO           | R   | UART A Status Register  |
| 0x12    | SIO           | R/W | UART B Data Register    |
| 0x13    | SIO           | R   | UART B Status Register  |
| 0x20    | 8-bit Latch   | W   | LED Output              |
| 0x30-37 | Compact Flash | R/W | Compact Flash Registers |
| 0x70    | Flip-flop     | W   | RAM/ROM Page            |

## Schematics ##

### Z80 Main Board Schematics - [PDF](design_files/main_board/simple_Z80.pdf) ###
![Screenshot](images/simple_Z80_schematic.png)

### Compact Flash & Raspberry Pi Board - [PDF](design_files/CompactFlash/CompactFlash.pdf) ###

![Screenshot](images/compact_flash_schematic.png)

