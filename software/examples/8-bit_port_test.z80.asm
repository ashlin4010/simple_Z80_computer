;**************************************************************
;
;                      Output Port Test
;
;    This program tests that the LEDs are working it will count
;         in binary, outputing the current count to the LEDs
;**************************************************************


.org 0x00                               ;Set the starting address to zero
.storage $FF $00                        ;Add slight delay after reset


START:
    LD B, 0x00                          ;Initialise count to zero 

    LD A, B                             ;Zero output
    OUT (0x20), A

MAIN_LOOP:
    LD A, B                             ;Output count to port 20
    OUT (0x20), A

    INC B                               ;Increment count

    LD DE, 0x2FFF                       ;Approximately half second delay
DELAY:
    DEC DE
    LD A, D
    OR E
    JR NZ, DELAY

    JR MAIN_LOOP                        ;Loop for ever 