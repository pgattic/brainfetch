
# Rust Implementation

BrainF*** Interpreter/VM written in Rust

By Preston Corless

## Usage

`cargo run --release -- [FILE.bf]`

## Performance

- Much safer than the C implementation
- Thanks to some nice optimization techniques, can run `/bf/mandelbrot.bf` in 6.624 secs on my machine
- Can run `/bf/hanoi.bf` in 0.332 seconds

