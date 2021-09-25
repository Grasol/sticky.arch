import serial
port = "COM4"




class ArduinoCache:
  def __init__(self, port):
    self.arduino = serial.Serial(port=port, baudrate=115200)

  def recv(self, n):
    return bytearray(self.arduino.read(n))

  def send(self, data):
    self.arduino.write(data)


def main():  
  arduino = ArduinoCache(port)

  while True:
    if arduino.arduino.in_waiting:
      header = arduino.recv(2)
      addr = header[1]
      if header[0]: # cache => ram
        ram = arduino.recv(64)

      else:
        for i in range(64):
          ram[i] = addr

        arduino.send(ram)


if __name__ == "__main__":
  main()