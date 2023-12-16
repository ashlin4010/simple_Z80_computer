# Simple Z80 Computer
The goal of this project was to build a minimally complex Z80 computer capable of running CP/M. While I have  not yet ported CP/M it should be capable of it.

Truthfully this is the second iteration and adds two useful additions, built in USB to serial converter and a Raspberry Pi zero emulating a terminal.


![Screenshot](images/simple_Z80_system.jpg)

## Specifications ##
* 64K Static RAM
* 32K ROM
* Z80 @ 4Mhz
* USB Keyboard via Raspberry Pi Zero
* Composite Video via Raspberry Pi Zero
* HDMI Video via Raspberry Pi Zero
* Suport for 27256 or AT28C256 ROM
* Compact Flash
* 8 LED indicators
* Built in USB to serial converter @ 9600 baud

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