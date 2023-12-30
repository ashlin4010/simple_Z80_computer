LD HL, HELP_STRING_START		;Print HELP_STRING
CALL PRINT_STRING

XOR A                           ;Set Zero flag
RET

HELP_STRING_START:

    .ascii "\r\n"

    // .ascii "  sload <address> <count>" "\r\n"
    // .ascii "    -Load binary data over serial port into the given address" "\r\n\r\n"

    .ascii "  sboot" "\r\n"
    .ascii "    -Load binary data over serial into the lower 32k and jump to 0x0000" "\r\n\r\n"

    .ascii "  clear" "\r\n"
    .ascii "    -Clear screen" "\r\n\r\n"

    // .ascii "  sdump <address> <count>" "\r\n"
    // .ascii "    -Load binary data over serial port into the given address" "\r\n\r\n"

    // .ascii "  get <address>" "\r\n"
    // .ascii "    -Get the value of memory at address" "\r\n\r\n"

    // .ascii "  put <address> <data>" "\r\n"
    // .ascii "    -Put data at the given address" "\r\n\r\n"

    // .ascii "  jump <address>" "\r\n"
    // .ascii "    -Jump to address" "\r\n\r\n"

    // .ascii "  setram" "\r\n"
    // .ascii "    -Enable lower RAM, disable ROM" "\r\n\r\n"

    // .ascii "  setrom" "\r\n"
    // .ascii "    -Enable ROM, disable lower RAM" "\r\n\r\n"

    // .ascii "  clear" "\r\n"
    // .ascii "    -Clear screen" "\r\n\r\n"

    // .ascii "  out <port> <value>" "\r\n"
    // .asciiz "    -Output value on given port" "\r\n\r\n"

    .asciiz "\r\n"