import serial
import serial.tools.list_ports

UART_NAME = "CH340"


class Command:
    PING = bytearray.fromhex("10")
    PONG = bytearray.fromhex("41")


def main():
    comport = get_uart()
    if comport is None:
        print("Unable to find UART, check connection")
        exit()

    uart = serial.Serial(comport.device, 9600, serial.EIGHTBITS, serial.PARITY_NONE, serial.STOPBITS_ONE, None, False)
    uart.flush()
    print("Connected to", uart.name)

    # Read input
    x = uart.read()
    if x == Command.PING:
        print("PING")
        uart.write(Command.PONG)
        uart.flush()

    uart.close()


def get_uart():
    for comport in serial.tools.list_ports.comports():
        if UART_NAME in comport.description:
            return comport
    return None


if __name__ == '__main__':
    main()
