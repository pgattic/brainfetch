
# Python implementation

BrainF*** JIT runtime written in Python

By Preston Corless

Python is already a pretty bottlenecked system. In order to maximise performance, this implementation does the following:

1. Optimizes the BrainF*** code into more optimal tokens
    - For example, `++++` (four separate increment operations) turns into `(ADD, 4)`
    - In addition, replaces all instances of `[-]` with a `ZERO` token
2. "Translates" the tokens into an executable Python string
3. AOT-compiles the Python string into Python bytecode
4. Directly executes the Python bytecode

## Usage

`uv run main.py [FILE.bf]`

## Performance

- Completes `hanoi.bf` in 7.974
- Completes `mandelbrot.bf` in 1:31.953

