
# Nushell Implementation

BrainF*** Interpreter written in Nushell

By Preston Corless

## Usage

This program is currently meant to be run within the Nushell REPL.

- `source brainfetch.nu`
- `brainfetch path/to/file.bf`

## Performance

This program currently takes over a minute to display just the first character of `/bf/mandelbrot.bf`. The main bottleneck is that it copies the entire memory array upon every memory update, which is due to Nushell's focus on immutable data.

- Can run `/bf/hello.bf` in 0.663
- Can run `/bf/ascii.bf` in 0.609

