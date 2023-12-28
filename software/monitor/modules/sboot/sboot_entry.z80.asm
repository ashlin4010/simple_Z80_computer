;*************************************************************************** 
;
;                          Serial Boot Program
;                               2023.12.27
;*************************************************************************** 

LD HL, PROGRAM                          ;Start of program
LD DE, PROGRAM_ADDRESS                  ;Load address
LD BC, PROGRAM_END - PROGRAM            ;Size of program
LDIR

JP PROGRAM_ADDRESS                      ;Jump to program

PROGRAM:
    .incbin "modules/sboot/sboot.bin"
PROGRAM_END:

PROGRAM_ADDRESS     .EQU    $8000       ;Program address