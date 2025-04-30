
# BrainFetch

This is a collection of BrainF*** interpreters and compilers I wrote in various languages, both as a test of my abilities and as a test of the general performance of the languages in everyday computation tasks.

The implementations can be found in the `src/` directory.

Current implementations include:

- C (most features)
- C-compiled (fastest)
- Python
- Rust (safest)
- Zig

## Implementation Methods

There are a few different ways to create a BrainF*** interpreter, and my implementations typically start as one but incrementally convert to another:

- Direct interpretation
    - Pattern match directly on the input string
    - Slowest but simplest approach
    - May filter out comments ahead of time
- Tokenization
    - Filter and convert the input code into a string of tokens to execute on a VM
    - Dramatic speedups with BF code that has comments
    - May also group repeated commands together (e.g. `++++` -> `(ADD, 4)`) which can result in ~2x performance boost in many cases
    - May also optimize frequently-used command strings by converting them into single tokens (e.g. `[-]` -> `ZERO`)
- JIT (Just-in-time) compilation
    - Convert the BF code into some existing language or bytecode and rely on an existing runtime to execute it
    - Easier to do with scripted languages that have an `exec` function
- AOT (Ahead-of-time) compilation
    - Convert the BF code into equivalent source code for a compiled language like C or Rust, compile the code into a native binary, and execute it directly

## Performance

Tests are run on a ThinkPad T480 with an Intel Core i5-8250U @ 3.40 GHz, running Arch Linux.

`mandelbrot.bf`:

| Language | Time |
| - | -:|
| C | 41.715 |
| C-aot | 0.991 |
| Python-jit | 1:31.953 |
| Rust | 6.786 |
| Zig | 37.700 |

## Useful Resources

- Wikipedia article on [BrainF***](https://en.wikipedia.org/wiki/Brainfuck)
- This [random GitHub repo](https://github.com/fabianishere/brainfuck/tree/master/examples) with a whole bunch of great examples

