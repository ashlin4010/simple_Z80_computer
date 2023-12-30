import os
import serial
import serial.tools.list_ports
import time

UART_NAME = "CH340"
MASK = b'\xF0'

FILES = {
    0: "./../monitor/monitor.bin"
}


class Command:
    PING = bytearray.fromhex("10")
    PONG = bytearray.fromhex("10")
    ACK = bytearray.fromhex("AA")
    NAK = bytearray.fromhex("55")

    SELECT_FILE = bytearray.fromhex("20")
    SET_START = bytearray.fromhex("30")
    SET_END = bytearray.fromhex("40")
    READ = bytearray.fromhex("50")


def main():

    selected_file = 0
    start_address = 0
    end_address = 32768

    comport = get_uart()
    if comport is None:
        print("Unable to find UART, check connection")
        exit()

    uart = serial.Serial(comport.device, 9600, serial.EIGHTBITS, serial.PARITY_NONE, serial.STOPBITS_ONE, 1, False)
    print("Connected to", uart.name)

    try:
        while True:
            x = uart.read()
            if len(x) == 0:continue
            if x == Command.PING:
                print("Received PING, sending PONG")
                uart.write(Command.PONG)
            elif bytes([x[0] & MASK[0]]) == Command.SELECT_FILE:
                # select the file to do download to the client
                file = int(str(x.hex())[1], 16)

                if file not in FILES:
                    print("No file exits!")
                    uart.write(Command.NAK)
                    continue

                file_path = FILES[file]
                if not os.path.isfile(file_path):
                    print("No file exits!")
                    uart.write(Command.NAK)
                    continue

                selected_file = file
                print("Selecting file:", file_path)
                uart.write(Command.ACK)

            elif x == Command.SET_START:
                MSB = uart.read()
                LSB = uart.read()
                if not (len(LSB) > 0 and len(MSB) > 0):
                    print("Error setting start_address")
                    uart.write(Command.NAK)
                    continue
                start_address = int.from_bytes(bytearray([MSB[0], LSB[0]]), "big")
                uart.write(Command.ACK)
                print("Setting start offset:", start_address)

            elif x == Command.SET_END:
                MSB = uart.read()
                LSB = uart.read()
                if not (len(LSB) > 0 and len(MSB) > 0):
                    print("Error setting end_address")
                    uart.write(Command.NAK)
                    continue
                end_address = int.from_bytes(bytearray([MSB[0], LSB[0]]), "big")
                uart.write(Command.ACK)
                print("Setting end offset:", end_address)

            elif x == Command.READ:
                print("Sending file")
                with open(FILES[selected_file], "rb") as file:
                    file.seek(start_address)
                    current_offset = start_address
                    while current_offset < end_address:
                        time.sleep(0.002)
                        current_offset += 1
                        byte = file.read(1)
                        if len(byte) == 0:
                            break
                        uart.write(byte)
                    time.sleep(1.2)
                    uart.write(Command.ACK)
                    print("Sending file complete\n")

    except KeyboardInterrupt:
        uart.close()


def get_uart():
    for comport in serial.tools.list_ports.comports():
        if UART_NAME in comport.description:
            return comport
    return None


if __name__ == '__main__':
    main()
