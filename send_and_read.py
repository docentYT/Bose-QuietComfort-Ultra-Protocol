import serial
import time

PORT = "COM4"


def send_and_read(hex_string):
    time.sleep(0.15)
    tx_bytes = bytes.fromhex(hex_string)

    with serial.Serial(PORT, 9600, timeout=1) as ser:
        ser.write(tx_bytes)
        print()
        print(f"Sent: {tx_bytes.hex().upper()}")

        was_seven = False
        while True:
            # Read header
            header = ser.read(4)
            if len(header) < 4:
                print("No full response")
                return

            cmd1, cmd2, status, length = header
            payload = ser.read(length)

            if len(payload) < length:
                print("Invalid payload")
                return

            frame = header + payload

            # Display HEX
            print("\n--- Recived frame ---")
            print(f"HEX:   {frame.hex(" ").upper()}")

            # Display ASCII
            ascii_repr = "".join(chr(b) if 32 <= b <= 126 else "." for b in frame)
            print(f"ASCII: {ascii_repr}")

            # Recive
            if status == 0x06:
                print("STATUS 6 -> end of the response")
                break

            if status == 0x07:
                was_seven = True
                print("STATUS 7 -> await more responses")
                continue

            if status == 0x03:
                if was_seven:
                    print("STATUS 3 -> no more responses but wait for 6")
                    continue
                else:
                    break
                    # continue

            print(f"Unkown status {status:02X}, stopped")
            break

        print("--- --- ---")
