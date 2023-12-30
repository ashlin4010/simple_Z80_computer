;**************************************************************
;
;                      Z80 Monitor Program
;                           2023.12.31
;                          (Incomplete)
;**************************************************************

; ROM Monitor
.ORG $00
.storage $FF $00                        ;Offset
JP INITIALISE                           ;Start

.include "libs/uart.z80.asm"
.include "libs/stack.z80.asm"
.include "libs/delay.z80.asm"

;***************************************************************************
;                           Constantes
;***************************************************************************
BOOT_FLAG           .EQU    $FFFF
STACK_POINTER       .EQU    $FFFD
INTRO_TEXT          .asciiz "\r\nMonitor - 2023.12.31\r\n"
NEW_LINE            .asciiz "\r\n"
MEMORY_START        .EQU    $8000       ;32k+

RETURN_CHAR         .EQU    $0D
SPACE_CHAR          .EQU    $20
BACKSPACE_CHAR      .EQU    $08
DEL_CHAR            .EQU    $7F

OUTPUT_BUFFER_REG   .EQU    $20

UART_AUTO_BOOT      .EQU    false

;UART_B = Raspberry Pi, UART_A = USB UART
UART_CONSOLE                .EQU    UART_B

;***************************************************************************
;                               Main
;***************************************************************************
INITIALISE:
    LD SP, STACK_POINTER                ;Set stack pointer

    WAIT_PI_BOOT()
    CLEAR_LEDS()                        ;Turn off leds
    UART_INIT()                         ;Setup UART

    LD HL, INTRO_TEXT			        ;Print intro text
    CALL PRINT_STRING

    .if UART_AUTO_BOOT
        JP SBOOT
    .endif

MAIN_LOOP:
    LD B, ">"
    CALL SEND_CHAR_UART                     ;Print cursor

    READ_INPUT(COMMAND_INPUT_BUFFER, 128)   ;Read user input into COMMAND_INPUT_BUFFER
    LD HL, NEW_LINE
    CALL PRINT_STRING

    LD HL, COMMAND_INPUT_BUFFER             ;Strip spaces out of COMMAND_INPUT_BUFFER and save into TEMP_BUFFER
    LD DE, TEMP_BUFFER
    CALL STRIP_STRINGS

    LD HL, TEMP_BUFFER                      ;Copy TEMP_BUFFER back to COMMAND_INPUT_BUFFER
    LD DE, COMMAND_INPUT_BUFFER
    CALL COPY_STRING

    LD HL, COMMAND_INPUT_BUFFER             ;Parse command and args into COMMAND_BUFFER and ARG_BUFFER_1-4
    CALL PARSE_COMMAND_LINE

    CALL RUN_COMMAND                        ;Try to run any commands

    JP MAIN_LOOP


;***************************************************************************
;WAIT_PI_BOOT
;macro: At the end of memory set AA. If on resert we can read AA
;then power has not be interrupted and we don't neeed to wait for the PI to boot
;***************************************************************************
.macro WAIT_PI_BOOT()
    LD A, (BOOT_FLAG)
    XOR $AA
    JR NZ, @WAIT

    JP @BOOT

    @WAIT:
        LD A, %11111111
        OUT (OUTPUT_BUFFER_REG), A
        CALL DEALY
        LD A, %11111110
        OUT (OUTPUT_BUFFER_REG), A
        CALL DEALY
        LD A, %11111100
        OUT (OUTPUT_BUFFER_REG), A
        CALL DEALY
        LD A, %11111000
        OUT (OUTPUT_BUFFER_REG), A
        CALL DEALY
        LD A, %11110000
        OUT (OUTPUT_BUFFER_REG), A
        CALL DEALY
        LD A, %11100000
        OUT (OUTPUT_BUFFER_REG), A
        CALL DEALY
        LD A, %11000000
        OUT (OUTPUT_BUFFER_REG), A
        CALL DEALY
        LD A, %10000000
        OUT (OUTPUT_BUFFER_REG), A
        CALL DEALY
        LD A, %00000000
        OUT (OUTPUT_BUFFER_REG), A
    @BOOT:
        LD A, $AA
        LD (BOOT_FLAG), A
.endmacro


;***************************************************************************
;PARSE_COMMAND
;***************************************************************************
PARSE_COMMAND_LINE:
    PUSH HL
    LD HL, COMMAND_BUFFER
    LD (HL), EOS
    LD HL, ARG_BUFFER_1
    LD (HL), EOS
    LD HL, ARG_BUFFER_2
    LD (HL), EOS
    LD HL, ARG_BUFFER_3
    LD (HL), EOS
    LD HL, ARG_BUFFER_4
    LD (HL), EOS
    POP HL

    LD DE, COMMAND_BUFFER
    CALL COPY_SUBSTRING
    LD A, (HL)
    XOR EOS
    JP Z, @END_OF_STRING
    INC HL

    LD DE, ARG_BUFFER_1
    CALL COPY_SUBSTRING
    LD A, (HL)
    XOR EOS
    JP Z, @END_OF_STRING
    INC HL

    LD DE, ARG_BUFFER_2
    CALL COPY_SUBSTRING
    LD A, (HL)
    XOR EOS
    JP Z, @END_OF_STRING
    INC HL

    LD DE, ARG_BUFFER_3
    CALL COPY_SUBSTRING
    LD A, (HL)
    XOR EOS
    JP Z, @END_OF_STRING
    INC HL

    LD DE, ARG_BUFFER_4
    CALL COPY_SUBSTRING

    @END_OF_STRING:
        RET


;***************************************************************************
;COPY_SUBSTRING
;Function: Walk and copy a string until a space or EOS
;Args:
;    HL - Input String Buffer - On exit HL points last byte in the string 
;    DE - Output String Buffer
;***************************************************************************
COPY_SUBSTRING:
    PUSH AF
    PUSH BC
    PUSH DE

    EX DE, HL                           ;Set first byte as EOS
    LD (HL), EOS
    EX DE, HL
@WALK
    LD B, (HL)

    LD A, B                             ;Read char from input
    XOR EOS                             ;If EOS jump
    JR Z, @END_OF_STRING

    LD A, B                             ;Copy char into A
    XOR " "                             ;If char is "space" then parse arg
    JR Z, @END_OF_STRING                ;Handle end of command

    PUSH HL                             ;Backup HL
    LD H, D
    LD L, E
    LD (HL), B                          ;Copy the value from input to output
    POP HL                              ;Restore HL

    INC HL                              ;INC input
    INC DE                              ;INC output
    JP @WALK                            ;Continue

@END_OF_STRING:
    PUSH HL                             ;Back up input pointer
    LD H, D
    LD L, E
    LD (HL), EOS                        ;Read EOS, write it and exit
    POP HL                              ;Restore input pointer

    POP DE
    POP BC
    POP AF
    RET

;***************************************************************************
;COMPARE_STRINGS
;Function: Given a string in HL and DE compare them
;Args:
;    HL - Buffer pointer one
;    DE - Buffer pointer two
;***************************************************************************
COMPARE_STRINGS:
    ; in use HL, DE, A, B
    LD C, $00                           ;Start offset 0

    @LOOP:
        PUSH HL                         ;Push string A pointer (Restore A)
        PUSH DE                         ;Push string B pointer (Restore B)
        PUSH DE                         ;Push string B pointer (Store for maths)

        LD DE, $00                      ;Set up offset for add
        LD E, C

        ADD HL, DE                      ;Add offset to string pointer
        LD A, (HL)                      ;Read char from string A + offset

        POP HL                          ;Pop string B pointer
        ADD HL, DE                      ;Add offset to string pointer
        LD B, (HL)                      ;Read char from string B + offset

        POP DE                          ;Pop string B pointer
        POP HL                          ;Pop string A pointer

        XOR B                           ;XOR chars A and B
        RET NZ

        LD A, B                         ;Char A and B are the same
        XOR EOS                         ;If B == 00 then A == 00
        RET Z

        INC C                           ;If (A == B) and (B != 00) then loop
        JR @LOOP


;***************************************************************************
;COPY_STRING
;Function: Copy a string to another buffer, stops on EOS
;Args:
;    HL - Buffer input
;    DE - Buffer Output
;***************************************************************************
COPY_STRING:
    SAVE_REGISTERS()

@WALK
    LD B, (HL)
    LD A, B                             ;Read char from input
    XOR EOS                             ;If EOS jump
    JR Z, @EOS

    PUSH HL                             ;Backup HL
    LD H, D
    LD L, E
    LD (HL), B                          ;Copy the value from input to output
    POP HL                              ;Restore HL

    INC HL                              ;INC input
    INC DE                              ;INC output
    JP @WALK                            ;Continue

@EOS
    LD H, D
    LD L, E
    LD (HL), EOS                        ;Read EOS, write it and exit
    RESTORE_REGISTERS()
    RET


;***************************************************************************
;STRIP_STRINGS
;Function: Remove leading, trailing and extra whitespaces
;Args:
;    HL - Buffer input
;    DE - Buffer Output
;***************************************************************************
STRIP_STRINGS:
    SAVE_REGISTERS()
    LD C, $01                           ;Zero flag
@WALK
    LD B, (HL)                          ;Read char into B
    INC HL

    LD A, B                             ;Move char to A
    XOR EOS                             ;If EOS jump
    JR Z, @EOS

    LD A, B                             ;Move char to A
    XOR SPACE_CHAR                      ;If space jump
    JR Z, @SPACE

    PUSH HL                             ;Backup HL
    LD H, D
    LD L, E
    LD (HL), B                          ;Write char to output
    INC DE                              ;INC DE (output)
    POP HL                              ;Restore HL
    LD C, $00                           ;Set flag off, allow
    JP @WALK                            ;Continue
@SPACE
    LD A, C                             ;If flag is set do not write anything
    LD C, $01                           ;Set flag as we just seen space
    XOR $01
    JR Z, @WALK

    PUSH HL                             ;Backup HL
    LD H, D
    LD L, E
    LD (HL), SPACE_CHAR                 ;Write space
    INC DE                              ;INC output buffer
    POP HL
    JP @WALK
@EOS
    LD H, D
    LD L, E
    DEC HL
    LD A, (HL)                          ;Read last output char
    XOR SPACE_CHAR                      ;If not space to EXIT
    JR NZ, @EXIT
    LD (HL), EOS                        ;Else replace with EOS

@EXIT
    LD H, D
    LD L, E
    LD (HL), EOS                        ;Read EOS, write it and exit
    RESTORE_REGISTERS()
    RET


;***************************************************************************
;SEND_CHAR_UART
;Function: Send a byte out of the UART
;***************************************************************************
SEND_CHAR_UART:
    SEND_BYTE_UART(UART_CONSOLE)


;***************************************************************************
;READ_CHAR_UART
;Function: Read char from UART into A
;***************************************************************************
READ_CHAR_UART:
    READ_BYTE_UART(UART_CONSOLE)


;***************************************************************************
;PRINT_STRING
;Function: Read string and send out over UART
;Args: hl - start of string in RAM
;***************************************************************************
PRINT_STRING:
    PRINT_STRING(SEND_CHAR_UART)

;***************************************************************************
;READ_LINE
;Function: Read an input into a buffer, echo chars
;Args:
;    hl - Buffer pointer
;    b  - Buffer size
;***************************************************************************
READ_LINE:
    LD D, B                             ;Load count into D
    LD E, B                             ;Load limit into E

    LD B, H                             ; HL -> BC
    LD C, L
@READ
    CALL READ_CHAR_UART                 ;Read char
    LD H, A                             ;Backup char to H

    XOR RETURN_CHAR                     ;If return jump
    JR Z, @RETURN

    LD A, H
    XOR BACKSPACE_CHAR                  ;If backspace jump
    JR Z, @BACKSPACE

    LD A, H
    XOR DEL_CHAR                        ;If del jump
    JR Z, @BACKSPACE

    LD A, D                             ;Don't allow string to exceded bufferr
    XOR $01                             ;Reserve last character for EOS
    JR Z, @READ

    LD A, E                             ;Load limit into A
    SUB D                               ;Offset = limit - count
    ADD A, C                            ;Add C to Offset
    LD L, A                             ;Move Offset+C to L
    LD A, H                             ;Move char back into A
    LD H, B                             ; BC -> HL

    LD (HL), A                          ;Write char to buffer + offset
    LD B, A                             ;Move A into B
    CALL SEND_CHAR_UART                 ;Print char
    LD B, H                             ;We just killed B so we need to restore it from H

    DEC D                               ;Decrement buffer limit

    JR @READ                            ;Read again
@RETURN:
    LD A, E                             ;Load limit into A
    SUB D                               ;Offset = limit - count
    ADD A, C                            ;Add C to Offset
    LD L, A                             ;Move Offset+C to L
    LD H, B                             ; BC -> HL

    LD (HL), EOS                        ;Write end of string
    RET
@BACKSPACE
    LD A, D                             ;Do not backspace out of the buffer LOL
    XOR E                               ;If D == E then @ start, jump read
    JR Z, @READ
    LD H, B                             ;Backup B

    LD B, BACKSPACE_CHAR                ;Backspace
    CALL SEND_CHAR_UART
    LD B, SPACE_CHAR                    ;Space
    CALL SEND_CHAR_UART
    LD B, BACKSPACE_CHAR                ;Backspace
    CALL SEND_CHAR_UART

    LD B, H                             ;Restore H
    INC D
    JR @READ


;***************************************************************************
;MATCH_AND_RUN_COMMAND
;macro: If INPUT_COMMAND matches COMMAND_STRING then jump to COMMAND_ENTRY
;***************************************************************************
.macro MATCH_AND_RUN_COMMAND(INPUT_COMMAND, COMMAND_STRING, COMMAND_ENTRY)
    LD HL, INPUT_COMMAND               ;Console STRING_BUFFER
    LD DE, COMMAND_STRING               ;Command string
    CALL COMPARE_STRINGS                ;Compare strings
    JP Z, COMMAND_ENTRY                 ;If match jump to command
    RET Z                               ;If Zero is set command was ran so exit
.endmacro


;***************************************************************************
;READ_INPUT
;macro: Read input in to BUFFER of LENGTH
;***************************************************************************
.macro READ_INPUT(BUFFER, LENGTH)
    LD HL, BUFFER
    LD B, LENGTH
    CALL READ_LINE
.endmacro


;***************************************************************************
;INIT_BUFFER
;macro: Initialise BUFFER of LENGTH
;***************************************************************************
.macro INIT_BUFFER(BUFFER, LENGTH, VALUE)
    PUSH HL
    LD HL, BUFFER
    .loop LENGTH
        LD (HL), VALUE
        INC HL
    .endloop
    POP HL
.endmacro

;***************************************************************************
;CLEAR_LEDS
;Macro: Clears LEDs
;***************************************************************************
.macro CLEAR_LEDS()
    LD A, $00
    OUT (OUTPUT_BUFFER_REG), A
.endmacro

;***************************************************************************
;DEALY
;Function: Wait some amount of time
;***************************************************************************
DEALY:
    DEALY($FFFF)


;***************************************************************************
;RUN_COMMAND
;Function: Try match and run a command
;***************************************************************************
RUN_COMMAND:
    MATCH_AND_RUN_COMMAND(COMMAND_BUFFER, HELP_COMMAND_STRING, HELP_TEXT)
    MATCH_AND_RUN_COMMAND(COMMAND_BUFFER, SBOOT_COMMAND_STRING, SBOOT)
    MATCH_AND_RUN_COMMAND(COMMAND_BUFFER, CLEAR_COMMAND_STRING, CLEAR)

    LD HL, COMMAND_BUFFER
    LD A, (HL)                          ;Get the first char
    XOR EOS
    RET Z                               ;If first char is 00 do nothing

    LD HL, COMMAND_NOT_FOUND            ;Command not found
    CALL PRINT_STRING
    RET

    COMMAND_NOT_FOUND       .asciiz "\r\nCommand not found!\r\n\r\n"

;***************************************************************************
;Modules
;***************************************************************************
HELP_TEXT:      ;Print help text
    HELP_COMMAND_STRING     .asciiz "help"
    .include "modules/help.z80.asm"

SBOOT:          ;Boot from serial
    SBOOT_COMMAND_STRING    .asciiz "sboot"
    .include "modules/sboot/sboot_entry.z80.asm"

CLEAR:          ;Clear the screen
    CLEAR_COMMAND_STRING    .asciiz "clear"
    .include "modules/clear.z80.asm"


;***************************************************************************
;                               Storage
;                    WARNING: Keep Memory Aligned
;***************************************************************************
.org MEMORY_START
.align $100
TEMP_BUFFER             .storage 256       ;Allow 256 chars

COMMAND_INPUT_BUFFER    .storage 128       ;Allow 128 chars
ARG_BUFFER_1            .storage 32        ;Allow 32 chars
ARG_BUFFER_2            .storage 32        ;Allow 32 chars
ARG_BUFFER_3            .storage 32        ;Allow 32 chars
ARG_BUFFER_4            .storage 32        ;Allow 32 chars

COMMAND_BUFFER          .storage 32        ;Allow 32 chars