
# BrainFetch

This is a collection of BrainF*** interpreters I wrote in various languages, both as a test of my abilities and as a test of the general performance of the languages in everyday computation tasks.

The implementations can be found in the `src/` directory.

Current implementations include:

- C (most features)
- Python
- Rust (fastest, safest)

## Performance

Tests are run on a ThinkPad T480 with an Intel Core i5-8250U @ 3.40 GHz, running Arch Linux.

`mandelbrot.bf`:

| Language | Time |
| - | -:|
| C | 41.715 |
| Python | 1:31.953 |
| Rust | 6.786 |

## Useful Resources

- Wikipedia article on BrainF***
- This [random GitHub repo](https://github.com/fabianishere/brainfuck/tree/master/examples) with a whole bunch of great examples

