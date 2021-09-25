# sticky.arch

import serial

class ArduinoCache:
  def __init__(self, port):
    self.arduino = serial.Serial(port=port, baudrate=115200)

  def recv(self, n):
    return bytearray(self.arduino.read(n))

  def send(self, data):
    self.arduino.write(data)



