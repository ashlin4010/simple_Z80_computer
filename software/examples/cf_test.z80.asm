;**************************************************************
;
;                      CF Test Program
;
; This program tests that the Z80 can read from the CF card
; The code for this test comes from MatthewWCook and can be found
; here: https://github.com/MatthewWCook/Z80Project/tree/master
;**************************************************************


.ORG $00                                ;Set the starting address zero
.storage $FF $00                        ;Offset

NEW_LINE        .BYTE "\r\n",EOS        ;New line
EOS:            .EQU    $00             ;End of string
CF_SECT_BUFF    .EQU    $8000           ;CF data buffer
CF_BASE:        .EQU    $30
CF_DATA:	    .EQU    CF_BASE + $00   ; Data (R/W)
CF_ERR:		    .EQU	CF_BASE + $01   ; Error register (R)
CF_FEAT:	    .EQU	CF_BASE + $01	; Features (W)
CF_SECCO:	    .EQU	CF_BASE + $02	; Sector count (R/W)                         
CF_LBA0:	    .EQU	CF_BASE + $03	; LBA bits 0-7 (R/W, LBA mode)
CF_LBA1:	    .EQU	CF_BASE + $04	; LBA bits 8-15 (R/W, LBA mode)
CF_LBA2:	    .EQU	CF_BASE + $05	; LBA bits 16-23 (R/W, LBA mode)
CF_LBA3:	    .EQU	CF_BASE + $06	; LBA bits 24-27 (R/W, LBA mode)
CF_STAT:	    .EQU	CF_BASE + $07	; Status (R)
CF_CMD:		    .EQU	CF_BASE + $07	; Command (W)	

CALL UART_INIT                          ;Setup UART and CF
CALL CF_INIT

MAIN_LOOP:

    CALL DELAY                          ;Approximately 2 seconds
    CALL DELAY
    CALL DELAY
    CALL DELAY

    CALL CF_TEST                        ;Read CF into CF_SECT_BUFF

    LD HL, CF_SECT_BUFF                 ;Print CF_SECT_BUFF as string
    CALL PRINT_STRING

    LD HL, NEW_LINE                     ;Print new line
    CALL PRINT_STRING
    LD HL, NEW_LINE                     ;Print new line
    CALL PRINT_STRING

    JR MAIN_LOOP                        ;Loop


;***************************************************************************
;CF_INIT
;Function: Initialize CF to 8 bit data transfer mode
;***************************************************************************	
CF_INIT:
	CALL	LOOP_BUSY
	LD		A,0x01						;LD features register to enable 8 bit
	OUT		(CF_FEAT),A
	CALL	LOOP_BUSY
	LD		A,0xEF						;Send set features command
	OUT		(CF_CMD),A
	CALL	LOOP_BUSY
	RET

;***************************************************************************
;LOOP_BUSY
;Function: Loops until status register bit 7 (busy) is 0
;***************************************************************************	
LOOP_BUSY:
	IN		A, (CF_STAT)				;Read status
	AND		%10000000					;Mask busy bit
	JP		NZ,LOOP_BUSY				;Loop until busy(7) is 0
	RET

;***************************************************************************
;LOOP_CMD_RDY
;Function: Loops until status register bit 7 (busy) is 0 and drvrdy(6) is 1
;***************************************************************************	
LOOP_CMD_RDY:
	IN		A,(CF_STAT)					;Read status
	AND		%11000000					;mask off busy and rdy bits
	XOR		%01000000					;we want busy(7) to be 0 and drvrdy(6) to be 1
	JP		NZ,LOOP_CMD_RDY
	RET

;***************************************************************************
;LOOP_DAT_RDY
;Function: Loops until status register bit 7 (busy) is 0 and drq(3) is 1
;***************************************************************************		
LOOP_DAT_RDY:
	IN		A,(CF_STAT)					;Read status
	AND		%10001000					;mask off busy and drq bits
	XOR		%00001000					;we want busy(7) to be 0 and drq(3) to be 1
	JP		NZ,LOOP_DAT_RDY
	RET


;***************************************************************************
;CF_RD_CMD
;Function: Gets a sector (512 bytes) into RAM buffer.
;***************************************************************************			
CF_RD_CMD:
	CALL	LOOP_CMD_RDY				;Make sure drive is ready for command
	LD		A,$20						;Prepare read command
	OUT		(CF_CMD),A					;Send read command

	CALL	LOOP_DAT_RDY				;Wait until data is ready to be read
	IN		A,(CF_STAT)					;Read status
	AND		%00000001					;mask off error bit
	JP		NZ,CF_RD_CMD				;Try again if error
	LD 		HL,CF_SECT_BUFF
	LD 		B,0							;read 256 words (512 bytes per sector)
CF_RD_SECT:
	CALL	LOOP_DAT_RDY	
	IN 		A,(CF_DATA)					;get byte of ide data	
	LD 		(HL),A                      ;write data to address of HL
	INC 	HL                          ;increment HL

	CALL	LOOP_DAT_RDY
	IN 		A,(CF_DATA)					;get byte of ide data	
	LD 		(HL),A
	INC 	HL
	DJNZ 	CF_RD_SECT
	RET
	
;***************************************************************************
;CF_TEST
;Function: Read sector 0 into RAM buffer.
;***************************************************************************	
CF_MSG_1: .BYTE "CF Card Test\r\n",EOS
CF_MSG_2: .BYTE "Reading sector 0 into RAM buffer...\r\n",EOS
CF_MSG_3: .BYTE "Sector 0 read ...\r\n",EOS

CF_TEST:
	LD 		HL,CF_MSG_1					;Print some messages 
	CALL    PRINT_STRING
	LD 		HL,CF_MSG_2	
	CALL    PRINT_STRING

	CALL 	LOOP_BUSY                   ; Wait for CF
    
	LD 		A,0x01
	OUT 	(CF_SECCO),A				;Deal with only one sector at a time (512 bytes)

	CALL 	LOOP_BUSY

	LD      A,$00
	OUT		(CF_LBA0),A					;LBA 0:7
	CALL 	LOOP_BUSY

	LD      A,$00
	OUT		(CF_LBA1),A					;LBA 8:15
	CALL 	LOOP_BUSY

	LD      A,$00
	OUT 	(CF_LBA2),A					;LBA 16:23
	CALL 	LOOP_BUSY

	LD 		A,0xE0						;Selects CF as master
	OUT 	(CF_LBA3),A					;LBA 24:27 + DRV 0 selected + bits 5:7=111
	CALL	CF_RD_CMD
	LD 		HL,CF_MSG_3			
	CALL    PRINT_STRING
	RET

;***************************************************************************
;PRINT_STRING
;Function: Read string and send out over UART
;***************************************************************************
PRINT_STRING:

    LD B, (HL)                          ;Send char
    CALL SEND_CHAR_UART

    INC HL                              ;Get next char
    LD B, (HL)

    LD A, EOS                           ;If next char is not EOS jump start
    OR B 
    JR NZ, PRINT_STRING

    RET

;***************************************************************************
;SEND_CHAR_UART
;Function: Send char in B over UART
;***************************************************************************
SEND_CHAR_UART:

    IN A, (0x11)                        ;Read serial status reg
    LD D, A

    LD A, %00000100                     ;While bit 2 is not 1 check again
    AND D
    JR Z, SEND_CHAR_UART
 
    LD A, B                             ;Write Data  
    OUT (0x10), A

    RET

;***************************************************************************
;DELAY
;Function: Delay approximately half second delay
;***************************************************************************
DELAY:
    LD DE, 0x2FFF
DELAY_LOOP:
    DEC DE
    LD A, D
    OR E
    JR NZ, DELAY_LOOP
    RET

;***************************************************************************
;UART_INIT
;Function: Initialise UART
;***************************************************************************
UART_INIT:
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
    RET