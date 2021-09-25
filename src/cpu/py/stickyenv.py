# sticky.arch

import sys
sys.path.append(".")
import os
import struct
import msvcrt

import ram as ramm
import com

"""
def str2int(s):
  prefix = s[0:2]
  if prefix == "0x":
    base = 16

  elif prefix == "0b":
    base = 2

  else:
    base = 10

  try:
    return int(s, base)

  except:
    return None


def consoleLoad(cmd):
  if len(cmd) < 3:
    print("Wrong syntax")
    return

  try:
    with open(cmd[2], "rb") as f:
      data = bytearray(f.read())
  
  except:
    print(f"No such file or directory: {cmd[2]}")
    return
  
  addr = str2int(cmd[1])
  if addr is None:
    print("Wrong syntax")
    return

  max = addr + len(data)
  if max > 2**24:
    print("File is too big")
    return
  
  ram.ram[addr:max] = data

def consolePrint(cmd):
  pass

def consoleMemdump(cmd):
  if len(cmd) < 2:
    print("Wrong syntax")
    return

  with open(cmd[1], "wb") as f:
    f.write(ram.ram)

def consoleModf(cmd):
  pass

def console():
  help_str = """"""
 (* TODO: BP / BREAKPOINT <addr> *) 
 EXIT / enter                      exit from console
 H / HELP                          print command list
 L / LOAD <addr> <file>            load binary file to memory
 P / PRINT <addr> [nbytes]         print n-bytes of memory from address
 MEMDUMP <file>                    create memory dump
 M / MODF <addr> <value> <nbytes>  modify n-bytes of memory with value
 (* TODO: S / STEP *)
 X / SHUTDOWN                      shutdown stickyenv 
 """"""
  print("==> stickyenv has been stopped\n")

  while True:
    cmd = input().split()
    if len(cmd) == 0:
      return

    i = cmd[0].upper()
    if i == "EXIT" == 0:
      return

    elif i == "HELP" or i == "H":
      print(help_str)

    elif i == "LOAD" or i == "L":
      consoleLoad(cmd)

    elif i == "PRINT" or i == "P":
      consolePrint(cmd)

    elif i == "MEMDUMP":
      consoleMemdump(cmd)

    elif i == "MODF" or i == "M":
      consoleModf(cmd)

    elif i == "SHUTDOWN" or i == "X":
      exit(0)
      
    else:
      pass




"""
def memCom():
  if arduino.arduino.in_waiting:
    header = arduino.recv(4)
    print(hex(header[0]), hex((header[1] << 8) | header[2]), header[3], end='   ')
    addr = int.from_bytes(header[0:2], "big")
    flag = header[3]
    if flag: # cache => ram
      data = arduino.recv(64)
      ram.storeLine(addr, data)
      print(data, "\n")

    else: # cache <= ram
      data = ram.loadLine(addr)
      arduino.send(data)
      print(data, "\n")


def main():
  while True:
    memCom()




if __name__ == "__main__":
  argc = len(sys.argv)
  if argc != 2:
    print("usage: python3 stickyenv.py <port (e.g. COM3)>")

  port = sys.argv[1]

  arduino = com.ArduinoCache(port)
  ram = ramm.RAM(2**24)
  main()


