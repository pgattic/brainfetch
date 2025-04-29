import sys
import readchar
from pathlib import Path

INC_PTR = 1
DEC_PTR = 2
INC_VAL = 3
DEC_VAL = 4
PUT_CHAR = 5
GET_CHAR = 6
OPEN_BR = 7
CLOSE_BR = 8

def parse_code(code: str):
    mapping = {
        '>': INC_PTR,
        '<': DEC_PTR,
        '+': INC_VAL,
        '-': DEC_VAL,
        '.': PUT_CHAR,
        ',': GET_CHAR,
        '[': OPEN_BR,
        ']': CLOSE_BR,
    }
    return [mapping[ch] for ch in code if ch in mapping]

def execute_code(code: list[int]):
    # Initialize memory
    prg_head = 0
    memory = bytearray(30_000)
    mem_ptr = 0

    # Execute the code
    while prg_head < len(code):
        cmd = code[prg_head]
        if code[prg_head] == INC_PTR:
            mem_ptr += 1
            if len(memory) <= mem_ptr:
                memory.append(0)
        elif code[prg_head] == DEC_PTR:
            mem_ptr -= 1
        elif code[prg_head] == INC_VAL:
            memory[mem_ptr] = (memory[mem_ptr] + 1) & 0xff
        elif code[prg_head] == DEC_VAL:
            memory[mem_ptr] = (memory[mem_ptr] - 1) & 0xff
        elif code[prg_head] == PUT_CHAR:
            sys.stdout.write(chr(memory[mem_ptr]))
            # print(chr(memory[mem_ptr]), end="")
        elif code[prg_head] == GET_CHAR:
            memory[mem_ptr] = ord(readchar.readchar())
        elif code[prg_head] == OPEN_BR:
            if memory[mem_ptr] == 0:
                bracket_bal = 1
                while bracket_bal > 0:
                    prg_head += 1
                    if code[prg_head] == OPEN_BR:
                        bracket_bal += 1
                    elif code[prg_head] == CLOSE_BR:
                        bracket_bal -= 1
        elif code[prg_head] == CLOSE_BR:
            bracket_bal = 1
            while bracket_bal > 0:
                prg_head -= 1
                if code[prg_head] == CLOSE_BR:
                    bracket_bal += 1
                elif code[prg_head] == OPEN_BR:
                    bracket_bal -= 1
            prg_head -= 1
        prg_head += 1

def main():
    # Open file from CLI args
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <filename>")
        sys.exit(1)

    filename = Path(sys.argv[1])
    try:
        content = filename.read_text(encoding="utf-8")
    except Exception as e:
        print(f"Error reading {filename}: {e}")
        sys.exit(1)

    execute_code(parse_code(content))


if __name__ == "__main__":
    main()

