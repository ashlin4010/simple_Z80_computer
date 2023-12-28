;*************************************************************************** 
;
;                          Serial Boot Program
;                               2023.12.27
;*************************************************************************** 
.ORG $8000
JP INITIALISE

.include "../../libs/uart.z80.asm"
.include "../../libs/stack.z80.asm"

;*************************************************************************** 
;                           Constantes
;***************************************************************************
BOOT_FLAG           .EQU    $FFFF
STACK_POINTER       .EQU    $FFFD
INTRO_TEXT          .asciiz "\r\nBooting from UART...\r\n"

;commands
COMMAND_PING        .EQU    $10

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

    LD HL, FOUND_TEXT
    CALL PRINT_STRING

END_LOOP:
    JP END_LOOP

    JP MAIN_LOOP
    FOUND_TEXT          .asciiz "\r\nServer Found\r\n"


;***************************************************************************
;WAIT_SERVER
;Function: Wait the file server to come online
;***************************************************************************
WAIT_SERVER:
    LD HL, WAIT_TEXT                ;Waiting for Server...
    CALL PRINT_STRING

@LOOP:
    LD B, COMMAND_PING              ;send COMMAND_PING
    CALL SEND_BYTE_UART_A

    READ_BYTE_UART_TIMEOUT(UART_A, @RESULT, @TIMEOUT)

    @TIMEOUT:
        LD B, "."
        CALL SEND_BYTE_UART_B
        CALL DEALY
        JP @LOOP

    @RESULT:
        RET

    WAIT_TEXT           .asciiz "\r\nWaiting for Server..."
    TIMEOUT_TEXT        .asciiz "\r\nTimeout!!\r\n"

;***************************************************************************
;SEND_BYTE_UART_B
;Function: Send a byte out of the UART
;***************************************************************************
SEND_BYTE_UART_B:
    SEND_BYTE_UART(UART_B)


;***************************************************************************
;SEND_BYTE_UART_A
;Function: Send a byte out of the UART
;***************************************************************************
SEND_BYTE_UART_A:
    SEND_BYTE_UART(UART_A)

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
    SAVE_REGISTERS()
        LD DE, 0xFFFF
    DELAY:
        DEC DE
        LD A, D
        OR E
        JR NZ, DELAY
    RESTORE_REGISTERS()
RET