;**************************************************************
;
;                      Z80 Monitor Program
;                           2023.11.13
;                          (Incomplete)
;**************************************************************

; ROM Monitor
.ORG $00
.storage $FF $00                        ;Offset
JP INITIALISE                           ;Start


;***************************************************************************
;                           Constantes
;***************************************************************************
STACK_POINTER       .EQU    $FFFF
INTRO_TEXT          .asciiz "\r\nMonitor, 2023.11.13\r\n"
NEW_LINE            .asciiz "\r\n"
EOS:                .EQU    $00         ;End of string
MEMORY_START        .EQU    $8000       ;32k+

RETURN_CHAR         .EQU    $0D
SPACE_CHAR          .EQU    $20
BACKSPACE_CHAR      .EQU    $08
DEL_CHAR            .EQU    $7F

UART_B_STATUS_REG   .EQU    $13
UART_B_DATA_REG     .EQU    $12

UART_A_STATUS_REG   .EQU    $11
UART_A_DATA_REG     .EQU    $10

OUTPUT_BUFFER_REG   .EQU    $20


;***************************************************************************
;                               Main
;***************************************************************************
INITIALISE:
    UART_INIT()                         ;Setup UART
    CLEAR_LEDS()                        ;Turn off leds

    LD SP, STACK_POINTER                ;Set stack pointer
    LD HL, INTRO_TEXT			        ;Print intro text
    CALL PRINT_STRING
    

MAIN_LOOP:
    LD B, ">"
    CALL SEND_CHAR_UART                 ;Print cursor

    READ_INPUT(COMMAND_INPUT_BUFFER, 128)

    LD HL, NEW_LINE
    CALL PRINT_STRING

    LD HL, COMMAND_INPUT_BUFFER
    LD DE, TEMP_BUFFER
    CALL STRIP_STRINGS

    LD HL, TEMP_BUFFER
    CALL PRINT_STRING

    LD B, "$"
    CALL SEND_CHAR_UART

    LD HL, NEW_LINE
    CALL PRINT_STRING


    LD HL, TEMP_BUFFER
    LD DE, COMMAND_INPUT_BUFFER
    CALL COPY_STRING

    LD HL, COMMAND_INPUT_BUFFER
    CALL PRINT_STRING

    LD HL, NEW_LINE
    CALL PRINT_STRING

    JP MAIN_LOOP


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
;Function: Send char in B over UART
;Args: B - char to send
;***************************************************************************
SEND_CHAR_UART:
    SAVE_REGISTERS()
@poll
    IN A, (UART_B_STATUS_REG)           ;Read serial status reg
    LD D, A
    LD A, %00000100                     ;While bit 2 is not 1 check again
    AND D
    JR Z, @poll
    LD A, B                             ;Write Data  
    OUT (UART_B_DATA_REG), A
    RESTORE_REGISTERS()
    RET


;***************************************************************************
;READ_CHAR_UART
;Function: Read char from UART into A
;***************************************************************************
READ_CHAR_UART:
    SAVE_REGISTERS()
@poll
    IN A, (UART_B_STATUS_REG)           ;Read serial status reg
    LD D, A
    LD A, %00000001                     ;While bit 0 is not 1 check again
    AND D
    JR Z, @poll
    RESTORE_REGISTERS()
    IN A, (UART_B_DATA_REG)             ;Read Data
    RET


;***************************************************************************
;PRINT_STRING
;Function: Read string and send out over UART
;Args: hl - start of string in RAM
;***************************************************************************
PRINT_STRING:
    SAVE_REGISTERS()
    LD A, (HL)                          ;Read the first char
    OR EOS
    JR NZ, @PRINT                       ;If EOS exit
    RESTORE_REGISTERS()
    RET
 @PRINT:
    LD B, (HL)                          ;Send char
    CALL SEND_CHAR_UART
    INC HL                              ;Get next char
    LD B, (HL)
    LD A, EOS                           ;If next char is not EOS jump start
    OR B 
    JR NZ, @PRINT
    RESTORE_REGISTERS()
    RET


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
;macro: If COMMAND_STRING matches STRING_BUFFER then jump to COMMAND_ENTRY
;***************************************************************************
.macro MATCH_AND_RUN_COMMAND(COMMAND_STRING, COMMAND_ENTRY)
    LD HL, COMMAND_BUFFER                ;Console STRING_BUFFER
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
;SAVE_REGISTERS
;***************************************************************************
.macro SAVE_REGISTERS()
    PUSH AF      ; Push register AF onto the stack
    PUSH BC      ; Push register BC onto the stack
    PUSH DE      ; Push register DE onto the stack
    PUSH HL      ; Push register HL onto the stack
.endmacro


;***************************************************************************
;RESTORE_REGISTERS
;***************************************************************************
.macro RESTORE_REGISTERS()
    POP HL       ; Pop the value from the stack into register HL
    POP DE       ; Pop the value from the stack into register DE
    POP BC       ; Pop the value from the stack into register BC
    POP AF       ; Pop the value from the stack into register AF
.endmacro


;***************************************************************************
;UART_INIT
;Macro: Initialise UART
;***************************************************************************
.macro UART_INIT()

    LD A, %00110000                     ;Error Reset A
    OUT (UART_A_STATUS_REG), A

    LD A, %00011000                     ;Reset A
    OUT (UART_A_STATUS_REG), A

    LD A, %00000100                     ;Select reg 4
    OUT (UART_A_STATUS_REG), A
    LD A, %01000100                     ;Clock mode x16 (01)
    OUT (UART_A_STATUS_REG), A          ;8 BIT SYNC CHARACTER (00)
                                        ;1 STOP BIT (01)
                                        ;PARITY EVEN/ODD (0)
                                        ;PARITY ENABLE (0)

    LD A, %00000001                     ;Select reg 1
    OUT (UART_A_STATUS_REG), A
    LD A, %00000000                     ;Wait/Ready Enable (000)
    OUT (UART_A_STATUS_REG), A          ;Receive Interrupt Mode 1 (0)
                                        ;Receive Interrupt Mode 0 (0)
                                        ;Status Affects Vector (0)
                                        ;Transmit Interrupt Enable (0)
                                        ;External Interrupts Enable (0)
    
    LD A, %00000011                     ;Select reg 3
    OUT (UART_A_STATUS_REG), A
    LD A, %11100001                     ;RX 8 BITS/CHARACTER 8 (11)
    OUT (UART_A_STATUS_REG), A          ;AUTO ENABLES (1)
                                        ;ENTER HUNT PHASE (0)
                                        ;RX CRC ENABLE (0)
                                        ;ADDRESS SEARCH MODE (SDLC) (0)
                                        ;SYNC CHARACTER LOAD INHIBIT (0)
                                        ;RX ENABLE (0)
    
    LD A, %00000101                     ;Select reg 5
    OUT (UART_A_STATUS_REG), A
    LD A, %01101000                     ;Data Terminal Ready HIGH (0)
    OUT (UART_A_STATUS_REG), A          ;8 Transmit Bits/Characters (11)
                                        ;Send Break (0)
                                        ;Transmit Enable (1)
                                        ;CRC-16 (0)
                                        ;Request To Send (0)
                                        ;Transmit CRC Enable (0)


    LD A, %00110000                     ;Error Reset B
    OUT (UART_B_STATUS_REG), A

    LD A, %00011000                     ;Reset B
    OUT (UART_B_STATUS_REG), A


    ;; Setup B
    LD A, %00000100                     ;Select reg 4
    OUT (UART_B_STATUS_REG), A
    LD A, %01000100                     ;Clock mode x16 (01)
    OUT (UART_B_STATUS_REG), A          ;8 BIT SYNC CHARACTER (00)
                                        ;1 STOP BIT (01)
                                        ;PARITY EVEN/ODD (0)
                                        ;PARITY ENABLE (0)

    LD A, %00000001                     ;Select reg 1
    OUT (UART_B_STATUS_REG), A
    LD A, %00000000                     ;Wait/Ready Enable (000)
    OUT (UART_B_STATUS_REG), A          ;Receive Interrupt Mode 1 (0)
                                        ;Receive Interrupt Mode 0 (0)
                                        ;Status Affects Vector (0)
                                        ;Transmit Interrupt Enable (0)
                                        ;External Interrupts Enable (0)
    
    LD A, %00000011                     ;Select reg 3
    OUT (UART_B_STATUS_REG), A
    LD A, %11100001                     ;RX 8 BITS/CHARACTER 8 (11)
    OUT (UART_B_STATUS_REG), A          ;AUTO ENABLES (1)
                                        ;ENTER HUNT PHASE (0)
                                        ;RX CRC ENABLE (0)
                                        ;ADDRESS SEARCH MODE (SDLC) (0)
                                        ;SYNC CHARACTER LOAD INHIBIT (0)
                                        ;RX ENABLE (0)
    
    LD A, %00000101                     ;Select reg 5
    OUT (UART_B_STATUS_REG), A
    LD A, %01101000                     ;Data Terminal Ready HIGH (0)
    OUT (UART_B_STATUS_REG), A          ;8 Transmit Bits/Characters (11)
                                        ;Send Break (0)
                                        ;Transmit Enable (1)
                                        ;CRC-16 (0)
                                        ;Request To Send (0)
                                        ;Transmit CRC Enable (0)

    LD A, %00110000                     ;Error Reset B
    OUT (UART_B_STATUS_REG), A

    LD A, %00010000                     ;Error Reset B
    OUT (UART_B_STATUS_REG), A

    LD A, %00101000                     ;Error Reset B
    OUT (UART_B_STATUS_REG), A


    LD A, %00000101                     ;Select reg 5
    OUT (UART_B_STATUS_REG), A
    LD A, %01101000                     ;Data Terminal Ready HIGH (0)
    OUT (UART_B_STATUS_REG), A          ;8 Transmit Bits/Characters (11)
                                        ;Send Break (0)
                                        ;Transmit Enable (1)
                                        ;CRC-16 (0)
                                        ;Request To Send (0)
                                        ;Transmit CRC Enable (0)
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

.print COMMAND_INPUT_BUFFER
.print ARG_BUFFER_1
.print ARG_BUFFER_2
.print ARG_BUFFER_3
.print ARG_BUFFER_4