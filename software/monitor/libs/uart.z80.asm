; this lib contains macros to work with the UART

UART_A              .EQU $00
UART_B              .EQU $01

EOS:                .EQU    $00         ;End of string

UART_B_STATUS_REG   .EQU    $13
UART_B_DATA_REG     .EQU    $12
UART_A_STATUS_REG   .EQU    $11
UART_A_DATA_REG     .EQU    $10

;***************************************************************************
;UART_INIT
;Macro: Initialise both UARTs for 9600 async serial
;***************************************************************************
.macro UART_INIT()

;--------------------------------Channel B----------------------------------------

    LD A, %00011000                     ;Channel Reset B
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
    LD A, %11000001                     ;RX 8 BITS/CHARACTER 8 (11)
    OUT (UART_B_STATUS_REG), A          ;AUTO ENABLES (0)
                                        ;ENTER HUNT PHASE (0)
                                        ;RX CRC ENABLE (0)
                                        ;ADDRESS SEARCH MODE (SDLC) (0)
                                        ;SYNC CHARACTER LOAD INHIBIT (0)
                                        ;Rx ENABLE (1)

    LD A, %00000101                     ;Select reg 5
    OUT (UART_B_STATUS_REG), A
    LD A, %01101000                     ;Data Terminal Ready HIGH (0)
    OUT (UART_B_STATUS_REG), A          ;8 Transmit Bits/Characters (11)
                                        ;Send Break (0)
                                        ;Transmit Enable (1)
                                        ;CRC-16 (0)
                                        ;Request To Send (0)
                                        ;Transmit CRC Enable (0)


    LD A, %00101000                     ;RESET TxINT PENDING B
    OUT (UART_B_STATUS_REG), A

    LD A, %00110000                     ;Error Reset B
    OUT (UART_B_STATUS_REG), A

    LD A, %00010000                     ;Error Reset B
    OUT (UART_B_STATUS_REG), A


    LD A, %11000000                     ;Reset Tx Underrun B
    OUT (UART_B_STATUS_REG), A

    LD A, %10000000                     ;Reset Tx CRC Generator B
    OUT (UART_B_STATUS_REG), A

    LD A, %10000000                     ;Reset Rx CRC checker B
    OUT (UART_B_STATUS_REG), A



;--------------------------------Channel A----------------------------------------

    LD A, %00011000                     ;Channel Reset A
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
    LD A, %11000001                     ;Rx 8 BITS/CHARACTER 8 (11)
    OUT (UART_A_STATUS_REG), A          ;AUTO ENABLES (0)
                                        ;ENTER HUNT PHASE (0)
                                        ;Rx CRC ENABLE (0)
                                        ;ADDRESS SEARCH MODE (SDLC) (0)
                                        ;SYNC CHARACTER LOAD INHIBIT (0)
                                        ;Rx ENABLE (1)

    LD A, %00000101                     ;Select reg 5
    OUT (UART_A_STATUS_REG), A
    LD A, %01101000                     ;Data Terminal Ready HIGH (0)
    OUT (UART_A_STATUS_REG), A          ;8 Transmit Bits/Characters (11)
                                        ;Send Break (0)
                                        ;Transmit Enable (1)
                                        ;CRC-16 (0)
                                        ;Request To Send (0)
                                        ;Transmit CRC Enable (0)


;-------------------------------- Reset ----------------------------------------
    LD A, %00101000                     ;RESET TxINT PENDING A
    OUT (UART_A_STATUS_REG), A

    LD A, %00110000                     ;Error Reset A
    OUT (UART_A_STATUS_REG), A

    LD A, %00010000                     ;Error Reset A
    OUT (UART_A_STATUS_REG), A


    LD A, %11000000                     ;Reset Tx Underrun A
    OUT (UART_A_STATUS_REG), A

    LD A, %10000000                     ;Reset Tx CRC Generator A
    OUT (UART_A_STATUS_REG), A

    LD A, %10000000                     ;Reset Rx CRC checker A
    OUT (UART_A_STATUS_REG), A

.endmacro

;***************************************************************************
;SEND_BYTE_UART
;Macro: Send a byte out of the UART
;***************************************************************************
.macro SEND_BYTE_UART(channel)
    UART_STATUS_REG .var 0
    UART_DATA_REG .var 0

    .if channel == 0
        UART_STATUS_REG = UART_A_STATUS_REG
        UART_DATA_REG = UART_A_DATA_REG
    .endif

    .if channel == 1
        UART_STATUS_REG = UART_B_STATUS_REG
        UART_DATA_REG = UART_B_DATA_REG
    .endif

    PUSH AF      ; Push register AF onto the stack
    PUSH BC      ; Push register BC onto the stack

    @poll
        IN A, (UART_STATUS_REG)           ;Read serial status reg
        AND %00000100                     ;While bit 2 is not 1 check again
        JR Z, @poll
        LD A, B                            ;Write Data
        OUT (UART_DATA_REG), A


    @WAIT_SENT:
        IN A, (UART_STATUS_REG)           ;Read serial status reg
        AND %00000100                     ;While bit 2 is not 1 check again
        JR Z, @WAIT_SENT

    POP BC       ; Pop the value from the stack into register BC
    POP AF       ; Pop the value from the stack into register AF
    RET
.endmacro


;***************************************************************************
;READ_BYTE_UART
;Function: Read char from UART into A
;***************************************************************************
.macro READ_BYTE_UART(channel)
    .if channel == 0
        UART_STATUS_REG = UART_A_STATUS_REG
        UART_DATA_REG = UART_A_DATA_REG
    .endif

    .if channel == 1
        UART_STATUS_REG = UART_B_STATUS_REG
        UART_DATA_REG = UART_B_DATA_REG
    .endif

    PUSH AF
@poll
    IN A, (UART_STATUS_REG)             ;Read serial status reg
    AND %00000001                       ;While bit 0 is not 1 check again
    JR Z, @poll
    POP AF
    IN A, (UART_DATA_REG)               ;Read Data after pop to replace just A
    RET
.endmacro


;***************************************************************************
;READ_BYTE_UART_TIMEOUT
;Function: Read byte from UART into A then jump to result
; if more then FFFF polls then jump to timeout
;***************************************************************************
.macro READ_BYTE_UART_TIMEOUT(channel, result, timeout)
    .if channel == 0
        UART_STATUS_REG = UART_A_STATUS_REG
        UART_DATA_REG = UART_A_DATA_REG
    .endif

    .if channel == 1
        UART_STATUS_REG = UART_B_STATUS_REG
        UART_DATA_REG = UART_B_DATA_REG
    .endif

    PUSH HL
    PUSH AF
    LD HL, 0xFFFF                       ;Timeout counter

@poll
    DEC HL                              ;Check timeout
    LD A, H
    OR L
    JR Z, @timeout_uart

    IN A, (UART_STATUS_REG)             ;Check for byte
    AND %00000001
    JR Z, @poll
    POP AF
    POP HL
    IN A, (UART_DATA_REG)             ;Read Data
    JP result

@timeout_uart:
    POP AF
    POP HL
    JP timeout
.endmacro


;***************************************************************************
;PRINT_STRING
;Function: Read string and send out over UART
;Args: hl - start of string in RAM
;***************************************************************************
.macro PRINT_STRING(SEND_UART)
    PUSH AF
    PUSH BC
    PUSH HL
    LD A, (HL)                          ;Read the first char
    OR EOS
    JR NZ, @PRINT                       ;If EOS exit
    POP HL
    POP BC
    POP AF
    RET
 @PRINT:
    LD B, (HL)                          ;Send char
    CALL SEND_UART
    INC HL                              ;Get next char
    LD B, (HL)
    LD A, EOS                           ;If next char is not EOS jump start
    OR B
    JR NZ, @PRINT
    POP HL
    POP BC
    POP AF
    RET
.endmacro