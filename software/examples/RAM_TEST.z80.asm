;**************************************************************
;
;                      Z80 RAM Test
;
;           This program tests the uper 32K of RAM
;              This program does not use any RAM
;**************************************************************

.ORG $00                                ;Set the starting address zero
.setting "HandleLongBranch", true


.Loop 64                                ; pad file with nop
    nop
.endloop

DEBUG:          .EQU    FALSE
EOS:            .EQU    $00             ;End of string
START_ADDRESS   .EQU    $8000           ;Starting address
END_ADDRESS     .EQU    $FFFF           ;End address
STRING_POINTER  .var    $0000



;***************************************************************************
;                       Program Start
;***************************************************************************
UART_INIT()                             ;Setup UART

LD DE, START_ADDRESS                    ;Set starting address
PRINT_STRING(INTRO_TEXT, 24)
PRINT_STRING(NEW_LINE, 2)

MAIN_LOOP:

    LD A, D
    OUT (0x20), A

    .if DEBUG
    PRINT_STRING(HEX_STR, 2)            ;"0x"
    PRINT_ADDRESS()                     ;Address (FFFF)
    PRINT_STRING(HEX_SPACE, 2)          ;": "
    .endif

    LD_HL_DE()                          ;Write pattern to ram
    TEST_PATTERN($00)                   ;Read count from ram
    JR NZ, FAIL_TEST                    ;If not zero test failed


    LD_HL_DE()                          ;Write pattern to ram
    TEST_PATTERN($FF)                   ;Read pattern from ram
    JR NZ, FAIL_TEST                    ;If not zero test failed

    LD_HL_DE()                          ;Write pattern to ram
    TEST_PATTERN($AA)                   ;Read pattern from ram
    JR NZ, FAIL_TEST                    ;If not zero test failed

    LD_HL_DE()                          ;Write pattern to ram
    TEST_PATTERN($55)                   ;Read pattern from ram
    JR NZ, FAIL_TEST                    ;If not zero test failed

    LD_HL_DE()                          ;Write pattern to ram
    TEST_PATTERN($99)                   ;Read pattern from ram
    JR NZ, FAIL_TEST                    ;If not zero test failed

    .if DEBUG
    PRINT_STRING(PASS_STRING, 4)        ;Must have passed, good job!
    PRINT_STRING(NEW_LINE, 2)           ;Newline
    .endif
    JR PASS_TEST                        ;You may CONTINUE


FAIL_TEST:
    PRINT_STRING(HEX_STR, 2)            ;"0x"
    PRINT_ADDRESS()                     ;Address (FFFF)
    PRINT_STRING(HEX_SPACE, 2)
    PRINT_STRING(FAIL_STRING, 4)        ;FAIL
    PRINT_STRING(NEW_LINE, 2)
    halt


PASS_TEST:
    LD HL, END_ADDRESS
    LD A, D
    XOR H                               ;If current adress and end address
    JR NZ, CONTINUE                     ;are diffrent keep going
    LD A, E
    XOR L
    JR NZ, CONTINUE
    JR END_TEST
CONTINUE:
    INC DE
    JR MAIN_LOOP

END_TEST:
    PRINT_STRING(TEST_END, 41)          ;PRINT "Test passed"
    PRINT_STRING(NEW_LINE, 2)
    halt

;***************************************************************************
;UART_INIT
;Macro: Initialise UART
;***************************************************************************
.macro UART_INIT()
    LD A, %00110000
    OUT (0x11), A
    LD A, %00110000
    OUT (0x13), A
    LD A, %00011000
    OUT (0x11), A
    LD A, %00011000
    OUT (0x13), A
    LD A, %00000100
    OUT (0x11), A
    LD A, %01000100
    OUT (0x11), A
    LD A, %00000001
    OUT (0x11), A
    LD A, %00000100
    OUT (0x11), A
    LD A, %00000011
    OUT (0x11), A
    LD A, %11100000
    OUT (0x11), A
    LD A, %00000101
    OUT (0x11), A
    LD A, %01101000
    OUT (0x11), A
.endmacro


;***************************************************************************
;SEND_CHAR_UART
;: Send char at CHAR_ADDRESS over UART
;***************************************************************************
.macro SEND_CHAR_UART(CHAR_ADDRESS)

    LD HL, CHAR_ADDRESS
    LD B, (HL)

    START:
    IN A, (0x11)                        ;Read serial status reg
    LD C, A

    LD A, %00000100                     ;While bit 2 is not 1 check again
    AND C
    JR Z, START
 
    LD A, B                             ;Write Data  
    OUT (0x10), A
.endmacro


;***************************************************************************
;SEND_CHAR_UART_B
;: Send char in B over UART
;***************************************************************************
.macro SEND_CHAR_UART_B()

    START:
    IN A, (0x11)                        ;Read serial status reg
    LD C, A

    LD A, %00000100                     ;While bit 2 is not 1 check again
    AND C
    JR Z, START
 
    LD A, B                             ;Write Data  
    OUT (0x10), A
.endmacro



;***************************************************************************
;PRINT_STRING
;Macro: Read string and send out over UART
;***************************************************************************
.macro PRINT_STRING(STRING_ADDRESS, LENGTH)
    .while STRING_POINTER != LENGTH
    SEND_CHAR_UART(STRING_ADDRESS + STRING_POINTER)
    STRING_POINTER = STRING_POINTER + 1
    .endwhile
    STRING_POINTER = $0000
.endmacro

;***************************************************************************
;PRINT_ADDRESS
;Macro: Send word over UART as string
;***************************************************************************
.macro PRINT_ADDRESS()

    ; Get hex X000                 
    LD H, D                             ;Load address into HL
    LD L, E

    LD A, H                             ;Get higher bytes
    SRL A
    SRL A
    SRL A
    SRL A                               ;Shift bit down (X0|00) -> (0X)

    ; Map A to Ascii and send UART
    LD HL, $00                          ;Clear HL
    LD L, A                             ;Place byte in L
    LD BC, HEX_MAP                      ;Place HEX_MAP address in BC
    ADD HL, BC                          ;Offset HEX_MAP by L eg, 10 maps to A
    LD B, (HL)                          ;Get Ascii code from HEX_MAP + offset
    SEND_CHAR_UART_B()

    ; Get hex 0X00
    LD H, D                             ;Load address into HL
    LD L, E
    LD B, H                             ;Get higher bytes
    LD A, %00001111                     
    AND B                               ;Get lower of the bytes (0X|00) -> (0X)

    ; Map A to Ascii and send UART
    LD HL, $00                          ;Clear HL
    LD L, A                             ;Place byte in L
    LD BC, HEX_MAP                      ;Place HEX_MAP address in BC
    ADD HL, BC                          ;Offset HEX_MAP by L eg, 10 maps to A
    LD B, (HL)                          ;Get Ascii code from HEX_MAP + offset
    SEND_CHAR_UART_B()

    ; Get hex 00X0
    LD H, D                             ;Load address into HL
    LD L, E
    LD A, L                             ;Get higher bytes
    SRL A
    SRL A
    SRL A
    SRL A                               ;Shift bit down (X0|00) -> (0X)

    ; Map A to Ascii and send UART
    LD HL, $00                          ;Clear HL
    LD L, A                             ;Place byte in L
    LD BC, HEX_MAP                      ;Place HEX_MAP address in BC
    ADD HL, BC                          ;Offset HEX_MAP by L eg, 10 maps to A
    LD B, (HL)                          ;Get Ascii code from HEX_MAP + offset
    SEND_CHAR_UART_B()

    LD H, D                             ;Load address into HL
    LD L, E
    LD B, L                             ;Get higher bytes
    LD A, %00001111                     
    AND B                               ;Get lower of the bytes (0X|00) -> (0X)

    ; Map A to Ascii and send UART
    LD HL, $00                          ;Clear HL
    LD L, A                             ;Place byte in L
    LD BC, HEX_MAP                      ;Place HEX_MAP address in BC
    ADD HL, BC                          ;Offset HEX_MAP by L eg, 10 maps to A
    LD B, (HL)                          ;Get Ascii code from HEX_MAP + offset
    SEND_CHAR_UART_B()


    SEND_CHAR_UART(":")
    SEND_CHAR_UART(" ")

.endmacro


;***************************************************************************
;LD_HL_DE
;Macro: LD HL, DE
;***************************************************************************
.macro LD_HL_DE()
    LD H, D                             ;Load address into HL
    LD L, E
.endmacro


;***************************************************************************
;TEST_PATTERN
;Macro: Write the given pattern to RAM, read it back and XOR
;***************************************************************************
.macro TEST_PATTERN(PATTERN)
    LD (HL), PATTERN                    ;Write pattern to ram
    LD A, (HL)                          ;Read count from ram
    XOR PATTERN
.endmacro

INTRO_TEXT      .asciiz "Z80 RAM Test, 2023.07.02"
TEST_TEXT       .asciiz "THIS IS A TEST!!!"
TEST_END        .asciiz "Test complete, all addresses have passed!"
HEX_MAP         .asciiz "0123456789ABCDEF"
NEW_LINE        .asciiz "\r\n"
PASS_STRING     .asciiz "PASS"
FAIL_STRING     .asciiz "FAIL"
HEX_STR         .asciiz "0x"
PATTERN_00      .asciiz "00000000 "
PATTERN_FF     .asciiz "11111111 "
PATTERN_AA     .asciiz "10101010 "
PATTERN_55     .asciiz "01010101 "
PATTERN_99     .asciiz "10011001 "
HEX_SPACE      .asciiz ": "