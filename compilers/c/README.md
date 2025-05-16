
# C-Compiled Implementation

BrainF*** Compiler

By Preston Corless

This implementation optimizes the BrainF*** code and converts it into C code, then compiles it as an executable.

1. Optimizes the BrainF*** code into more optimal tokens
    - For example, `++++` (four separate increment operations) turns into `(ADD, 4)`
    - In addition, replaces all instances of `[-]` with a `ZERO` token
2. "Translates" the tokens into a C program
3. Compiles the C program using the system's C compiler (`cc`) with `-O3` optimization

## Usage

1. `uv run main.py [FILE.bf]`
2. `out/[FILE]`

## Performance

- Completes `hanoi.bf` in 0.170
- Completes `mandelbrot.bf` in 0.991

