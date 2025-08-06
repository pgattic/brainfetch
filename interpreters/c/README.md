
# C Implementation

A BrainF*** interpreter/debugger written in standard C

By Preston Corless

## Usage

`brainfetch [FILE].bf [-d]`

## Notes

- Note that this was the first interpreter made in this project, so it was made with the least skill, and there is much room for improvement.
- This interpreter has static Pogram and Work memory allocations, meaning it has a limit to both code size and memory access size.
    - Change the "#define"s to accomodate larger programs or memory.
- Debug mode: enabled with "-d"
    - Slower and less memory-efficient code execution, but provides more helpful error messages and breakpoints.
    - When active, the asterisk (*) command works as a breakpoint, upon which a small memory dump is displayed and the program ends.

## Performance

- Executes `/bf/mandelbrot.bf` in ~41.7 seconds on average on my machine
- Executes `/bf/hanoi.bf` in ~1.086 seconds

