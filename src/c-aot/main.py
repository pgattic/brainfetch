import sys
import os
import subprocess
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
        '>': INC_PTR, '<': DEC_PTR,
        '+': INC_VAL, '-': DEC_VAL,
        '.': PUT_CHAR, ',': GET_CHAR,
        '[': OPEN_BR, ']': CLOSE_BR,
    }
    return [mapping[ch] for ch in code if ch in mapping]

# Perform a sort-of RLE of program
def optimize_code(code: list[int]):
    result = []
    last_cmd = None
    count = 1
    for cmd in code:
        if cmd == last_cmd and cmd in (INC_PTR, DEC_PTR, INC_VAL, DEC_VAL, PUT_CHAR):
            count += 1
        elif last_cmd is not None:
            result.append((last_cmd, count))
            count = 1
        last_cmd = cmd
    result.append((last_cmd, count))

    # `[-]` Optimization
    for i, cmd in enumerate(result):
        if i < len(result) - 2 and result[i:i+3] == [(OPEN_BR, 1), (DEC_VAL, 1), (CLOSE_BR, 1)]:
            result[i:i+3] = [(ZERO, 1)]

    return result

# Turn a given BF command into a line of Python code
def jit_cmd(cmd: int, count: int):
    if cmd == INC_PTR: return f"mem_ptr += {count};"
    elif cmd == DEC_PTR: return f"mem_ptr -= {count};"
    elif cmd == INC_VAL: return f"memory[mem_ptr] += {count};"
    elif cmd == DEC_VAL: return f"memory[mem_ptr] -= {count};"
    elif cmd == ZERO: return f"memory[mem_ptr] = 0;"
    elif cmd == PUT_CHAR: return "putchar(memory[mem_ptr]);" if count == 1 else f"print_chars(memory[mem_ptr], {count});"
    elif cmd == GET_CHAR: return f"memory[mem_ptr] = getchar();"
    elif cmd == OPEN_BR: return "while (memory[mem_ptr] != 0) {"
    elif cmd == CLOSE_BR: return "}"

# Convert tokenized BF code into Python source code
def generate_jit_source(code: list[tuple[int, int]]):
    lines = [
        "#include <stdio.h>",
        "void print_chars(char ch, int count) {for (int i = 0; i < count; i++){putchar(ch);}}",
        "int main() {",
        "  unsigned char memory[30000] = {0};",
        "  int mem_ptr = 0;"
    ]

    indentation = 1
    for (cmd, count) in code:
        jit = jit_cmd(cmd, count)
        if cmd == CLOSE_BR: indentation -= 1
        if jit is not None:
            lines.append("  " * indentation + jit)
        if cmd == OPEN_BR: indentation += 1
    lines.append("}")

    return "\n".join(lines)

def compile_jit_source(source: str):
    namespace = {}
    compiled = compile(source, "<jit>", "exec")
    exec(compiled, namespace, namespace)
    return namespace

def main():
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
    c_program = generate_jit_source(code)

    program_name = filename.name.split(".")[0]
    os.makedirs("out", exist_ok=True)
    with open(f"out/{program_name}.c", "w") as c_file:
        c_file.write(c_program)
    subprocess.run(
        ["cc", f"out/{program_name}.c", "-O3", "-o", f"out/{program_name}"], 
        capture_output=True, 
        text=True,
        check=True
    )

if __name__ == "__main__":
    main()

