
# JavaScript Implementation

BrainF*** JIT compiler written in JavaScript

By Preston Corless

Note: This program is timed using `bun` as its JS runtime, which dramatically improves its performance. Interestingly, the other JS interpreter runs *slower* under `bun` than with `node`.

## Usage

`bun main.js [FILE.bf]`

## Performance

- Completes `mandelbrot.bf` in 3.893
- Completes `hanoi.bf` in 1.512

