@echo off

del /Q "modules\sboot\sboot.bin" 2>nul
del /Q "modules\sboot\sboot_entry.bin" 2>nul
del /Q "monitor.bin" 2>nul

retroassembler.exe -l modules\sboot\sboot.z80.asm && ^
retroassembler.exe -l modules\sboot\sboot_entry.z80.asm && ^
retroassembler.exe -l monitor.z80.asm

del /Q "modules\sboot\sboot.bin" 2>nul
del /Q "modules\sboot\sboot_entry.bin" 2>nul
