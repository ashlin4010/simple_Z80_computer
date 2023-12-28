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