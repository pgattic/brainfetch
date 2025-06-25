
# Rust Implementation

BrainF*** JIT Compiler Written in Rust

By Preston Corless

This is a JIT compiler for BrainF*** built using [Cranelift](https://cranelift.dev/). It works by compiling the BrainF*** code into machine code for the host machine and then executing it directly, all on-the-fly.

The upside to this approach is that after the BF code is analyzed, the computer is only executing a native machine code equivalent, but the downside is that it requires a larger startup time to compile BF code into machine code.

## Usage

`cargo run --release -- [FILE.bf]`

## Performance

- Can run `/bf/mandelbrot.bf` in 3.672 secs on my machine
- Can run `/bf/hanoi.bf` in 0.535 seconds

