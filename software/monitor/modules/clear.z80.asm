    ;1B5B324A
    LD B, $1B
    CALL SEND_CHAR_UART
    LD B, $5B
    CALL SEND_CHAR_UART
    LD B, $32
    CALL SEND_CHAR_UART
    LD B, $4A
    CALL SEND_CHAR_UART

    ;1B5B48
    LD B, $1B
    CALL SEND_CHAR_UART
    LD B, $5B
    CALL SEND_CHAR_UART
    LD B, $48
    CALL SEND_CHAR_UART

    XOR A                           ;Set Zero flag
    RET                             ;Return