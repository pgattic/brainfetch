
# Rust Implementation

BrainF*** Interpreter/VM written in Rust

By Preston Corless

## Usage

`cargo run --release -- [FILE.bf]`

## Performance

- Safer than the C implementation (but still has a few holes)
- Thanks to some nice optimization techniques, can run `/bf/mandelbrot.bf` in ~7.4 secs on average on my machine
    - With optimizations turned off, does the same thing in about ~38.8 seconds on average

