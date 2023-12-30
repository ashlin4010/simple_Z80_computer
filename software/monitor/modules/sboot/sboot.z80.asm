;***************************************************************************
;
;                          Serial Boot Program
;                               2023.12.27
;***************************************************************************
.ORG $8000
JP INITIALISE

.include "../../libs/uart.z80.asm"
.include "../../libs/stack.z80.asm"
.include "../../libs/delay.z80.asm"

;***************************************************************************
;                           Constantes
;***************************************************************************
INTRO_TEXT          .asciiz "\r\nBooting from UART...\r\n"
BOOT_FLAG           .EQU    $FFFF
STACK_POINTER       .EQU    $FFFD
DEFAULT_FILE        .EQU    $0
START_ADDRESS       .EQU    $0000
END_ADDRESS         .EQU    $1000   ;4096

;commands
COMMAND_ACK         .EQU    $AA
COMMAND_NAK         .EQU    $55

COMMAND_PING        .EQU    $10
COMMAND_PONG        .EQU    $10

COMMAND_SELECT_FILE .EQU    $20
COMMAND_SET_START   .EQU    $30
COMMAND_SET_END     .EQU    $40
COMMAND_READ_FILE   .EQU    $50


TIMEOUT_TEXT            .asciiz "Timeout!!\r\n"

;***************************************************************************
;                               Main
;***************************************************************************
INITIALISE:
    LD SP, STACK_POINTER                    ;set stack pointer

    LD C, 0x71                              ;swap ROM for RAM
    OUT (C)

    LD HL, INTRO_TEXT			            ;Print intro text
    CALL PRINT_STRING

MAIN_LOOP:
    CALL WAIT_SERVER
    CALL SELECT_FILE
    CALL SET_START_ADDRESS
    CALL SET_END_ADDRESS
    CALL READ_FILE

END_LOOP:
    JP END_LOOP

;***************************************************************************
;WAIT_SERVER
;Function: Wait the file server to come online
;***************************************************************************
WAIT_SERVER:
    LD HL, @WAIT_TEXT                ;Waiting for Server...
    CALL PRINT_STRING

@LOOP:
    LD B, COMMAND_PING              ;send COMMAND_PING
    CALL SEND_BYTE_UART_A

    READ_BYTE_UART_TIMEOUT(UART_A, @RESULT, @TIMEOUT)

    @TIMEOUT:
        LD B, "."
        CALL SEND_BYTE_UART_B
        JP @LOOP

    @RESULT:
        XOR COMMAND_PONG
        JR NZ, @LOOP
        LD HL, @FOUND_TEXT
        CALL PRINT_STRING
        RET

    @WAIT_TEXT           .asciiz "\r\nWaiting for Server..."
    @FOUND_TEXT          .asciiz "Server Found\r\n"

;***************************************************************************
;SELECT_FILE
;Function: Select the file to be pulled from the server
;***************************************************************************
SELECT_FILE:
    LD HL, FILE_SELECT_TEXT
    CALL PRINT_STRING

    LD A, COMMAND_SELECT_FILE
    OR DEFAULT_FILE                         ;set file index value
    LD B, A
    CALL SEND_BYTE_UART_A                   ;send file select command

    READ_BYTE_UART_TIMEOUT(UART_A, @RESULT, @TIMEOUT)

    @ERROR:                                 ;unable to select file (got NAK)
        LD HL, ERROR_TEXT
        CALL PRINT_STRING
        RET

    @TIMEOUT:                               ;timeout
        LD HL, TIMEOUT_TEXT
        CALL PRINT_STRING
        RET

    @RESULT:                                ;got responce
        XOR COMMAND_ACK
        JR NZ, @ERROR
        LD HL, FILE_SELECTED_TEXT
        CALL PRINT_STRING
        RET

    FILE_SELECT_TEXT        .asciiz "\r\nSelecting File..."
    FILE_SELECTED_TEXT      .asciiz "File Selected\r\n"
    ERROR_TEXT              .asciiz "Error Selecting File!\r\n"

;***************************************************************************
;SET_START_ADDRESS
;Function: Set the starting address of a file
;***************************************************************************
SET_START_ADDRESS:
    LD HL, @SET_OFFSET_TEXT
    CALL PRINT_STRING

    LD B, COMMAND_SET_START
    CALL SEND_BYTE_UART_A

    LD HL, START_ADDRESS

    LD B, H
    CALL SEND_BYTE_UART_A

    LD B, L
    CALL SEND_BYTE_UART_A

    READ_BYTE_UART_TIMEOUT(UART_A, @RESULT, @TIMEOUT)

    @ERROR:                                 ;unable to select file (got NAK)
        LD HL, @ERROR_TEXT
        CALL PRINT_STRING
        RET

    @TIMEOUT:                               ;timeout
        LD HL, TIMEOUT_TEXT
        CALL PRINT_STRING
        RET

    @RESULT:                                ;got responce
        XOR COMMAND_ACK
        JR NZ, @ERROR
        LD HL, @SUCCESS_TEXT
        CALL PRINT_STRING
        RET

    @SET_OFFSET_TEXT         .asciiz "\r\nSetting Start of File Offset..."
    @SUCCESS_TEXT            .asciiz "Set Start Offset\r\n"
    @ERROR_TEXT              .asciiz "Error Setting Start Offset!\r\n"

;***************************************************************************
;SET_END_ADDRESS
;Function: Set the end address of a file
;***************************************************************************
SET_END_ADDRESS:
    LD HL, @SET_END_TEXT
    CALL PRINT_STRING

    LD B, COMMAND_SET_END
    CALL SEND_BYTE_UART_A

    LD HL, END_ADDRESS

    LD B, H
    CALL SEND_BYTE_UART_A

    LD B, L
    CALL SEND_BYTE_UART_A

    READ_BYTE_UART_TIMEOUT(UART_A, @RESULT, @TIMEOUT)

    @ERROR:                                 ;unable to select file (got NAK)
        LD HL, @ERROR_TEXT
        CALL PRINT_STRING
        RET

    @TIMEOUT:                               ;timeout
        LD HL, TIMEOUT_TEXT
        CALL PRINT_STRING
        RET

    @RESULT:                                ;got responce
        XOR COMMAND_ACK
        JR NZ, @ERROR
        LD HL, @SUCCESS_TEXT
        CALL PRINT_STRING
        RET

    @SET_END_TEXT            .asciiz "\r\nSetting End of File Offset..."
    @SUCCESS_TEXT            .asciiz "Set End Offset\r\n"
    @ERROR_TEXT              .asciiz "Error Setting End of File Offset!\r\n"

;***************************************************************************
;READ_FILE
;Function: Read a file from the server
;***************************************************************************
READ_FILE:
    LD HL, @READ_FILE_TEXT
    CALL PRINT_STRING

    LD B, COMMAND_READ_FILE
    CALL SEND_BYTE_UART_A

    LD HL, $0000

@LOOP_PRINT:

    READ_BYTE_UART_TIMEOUT(UART_A, @RESULT, @TIMEOUT)

    @TIMEOUT:
        LD HL, @HALT_TEXT
        CALL PRINT_STRING
        JR @CONFIRMATION

    @RESULT:
        LD (HL), A
        INC HL
        JP @LOOP_PRINT

@CONFIRMATION:
    READ_BYTE_UART_TIMEOUT(UART_A, @CONFIRM, @TIMEOUT_CON)

    @ERROR:
        LD HL, @ERROR_TEXT
        CALL PRINT_STRING
        RET

    @TIMEOUT_CON:
        LD HL, TIMEOUT_TEXT
        CALL PRINT_STRING
        RET

    @CONFIRM:
        XOR COMMAND_ACK
        JR NZ, @ERROR

        LD HL, @SUCCESS_TEXT
        CALL PRINT_STRING

        CALL DEALY

        JP $0000

@READ_FILE_TEXT          .asciiz "\r\nReading File..."
@HALT_TEXT               .asciiz "Complete\r\n\r\nAwaiting Confirmation..."
@SUCCESS_TEXT            .asciiz "Complete\r\n\r\nJumping to $0000\r\n\r\n"
@ERROR_TEXT              .asciiz "Error Downloading!\r\n"




;***************************************************************************
;SEND_BYTE_UART_A
;Function: Send a byte out of the UART
;***************************************************************************
SEND_BYTE_UART_A:
    SEND_BYTE_UART(UART_A)

;***************************************************************************
;SEND_BYTE_UART_B
;Function: Send a byte out of the UART
;***************************************************************************
SEND_BYTE_UART_B:
    SEND_BYTE_UART(UART_B)

;***************************************************************************
;READ_CHAR_UART
;Function: Read char from UART into A
;***************************************************************************
READ_BYTE_UART_A:
    READ_BYTE_UART(UART_A)

;***************************************************************************
;PRINT_STRING
;Function: Read string and send out over UART
;Args: hl - start of string in RAM
;***************************************************************************
PRINT_STRING:
    PRINT_STRING(SEND_BYTE_UART_B)

;***************************************************************************
;DEALY
;Function: Wait some amount of time
;***************************************************************************
DEALY:
    DEALY($FFFF)