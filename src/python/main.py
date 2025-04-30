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
ZERO = 9

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

# Perform a sort-of RLE of program
def optimize_code(code: list[int]):
    result = []
    last_cmd = None
    count = 0
    for cmd in code:
        if cmd == last_cmd and cmd in (INC_PTR, DEC_PTR, INC_VAL, DEC_VAL, PUT_CHAR):
            count += 1
        else:
            if last_cmd is not None:
                result.append((last_cmd, count))
            count = 1
        last_cmd = cmd
    result.append((last_cmd, count))

    # `[-]` Optimization
    for i, cmd in enumerate(result):
        if cmd[0] == OPEN_BR and i < len(result) - 2 and result[i+1][0] == DEC_VAL and result[i+2][0] == CLOSE_BR:
            result[i:i+3] = [(ZERO, 1)]

    return result

def compute_bracket_lookup(code: list[tuple[int, int]]):
    jump_table = {}
    stack = []
    for idx, (cmd, _) in enumerate(code):
        if cmd == OPEN_BR:
            stack.append(idx)
        elif cmd == CLOSE_BR:
            start = stack.pop()
            jump_table[start] = idx
            jump_table[idx] = start
    return jump_table

def execute_code(code: list[(int, int)]):
    jump_table = compute_bracket_lookup(code)
    # Initialize memory
    prg_head = 0
    memory = bytearray(30_000)
    mem_ptr = 0
    code_len = len(code)

    # Execute the code
    while prg_head < code_len:
        (cmd, count) = code[prg_head]
        if cmd == INC_PTR: mem_ptr += count
        elif cmd == DEC_PTR: mem_ptr -= count
        elif cmd == INC_VAL: memory[mem_ptr] = (memory[mem_ptr] + count) & 0xff
        elif cmd == DEC_VAL: memory[mem_ptr] = (memory[mem_ptr] - count) & 0xff
        elif cmd == ZERO: memory[mem_ptr] = 0
        elif cmd == PUT_CHAR:
            sys.stdout.buffer.write(bytes([memory[mem_ptr]] * count))
            sys.stdout.flush()
        elif cmd == GET_CHAR: memory[mem_ptr] = ord(readchar.readchar())
        elif cmd == OPEN_BR:
            if memory[mem_ptr] == 0: prg_head = jump_table[prg_head]
        elif cmd == CLOSE_BR:
            if memory[mem_ptr] != 0: prg_head = jump_table[prg_head]

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

    code = optimize_code(parse_code(content))
    execute_code(code)


if __name__ == "__main__":
    main()

