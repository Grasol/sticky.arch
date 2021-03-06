import os
import sys
import subprocess

def main():
  argv = sys.argv
  argc = len(argv)
  if (argc != 2):
    print("Usage: python3 stickyasm.py <file.c>")
    sys.exit(0)

  name, ext = os.path.splitext(argv[1])
  input_name = argv[1]
  output_name = name + ".bin"
  exe_name = name + ".exe"

  command = [
    (f"gcc -c stickyasm.c -o tmp_sticky_asm_1.o -Wall -Wextra -O3",
      "compiling assembler...\n"),
    (f"gcc -c {input_name} -o tmp_sticky_asm_2.o -Wall -Wextra -O3",
      "compiling your program...\n"),
    (f"gcc tmp_sticky_asm_1.o tmp_sticky_asm_2.o -o {exe_name} -Wall -Wextra -O3",
      "linking...\n"),
    (f"{exe_name} {output_name}", 
      f"running {exe_name}...\n")
  ]

  for i in range(len(command)):
    print(command[i][1])
    subprocess.check_call(command[i][0], shell=True)


if __name__ == "__main__":
  main()



