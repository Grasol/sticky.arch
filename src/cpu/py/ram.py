# sticky.arch

class RAM:
  def __init__(self, sz):
    self.ram = bytearray(sz)

  def loadLine(self, addr):
    start = addr & 0xffffc0
    end = start + 64
    return self.ram[start:end]

  def storeLine(self, addr, line):
    start = addr & 0xffffc0
    end = start + 64
    if len(line) == 64:
      self.ram[start:end] = line 



