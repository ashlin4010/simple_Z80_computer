;***************************************************************************
;DEALY
;Function: Wait some amount of time
;***************************************************************************
.macro DEALY(COUNT)
    PUSH AF      ; Push register AF onto the stack
    PUSH DE      ; Push register DE onto the stack
    LD DE, COUNT
    @DELAY:
        DEC DE
        LD A, D
        OR E
        JR NZ, @DELAY
    POP DE       ; Pop the value from the stack into register DE
    POP AF       ; Pop the value from the stack into register AF
    RET
.endmacro
