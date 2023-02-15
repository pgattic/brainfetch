
# BrainFetch

A BrainF*** interpreter/debugger written in standard C

By Preston Corless

## Usage: 

`brainfetch [filename].bf [-d]`

## Notes:
- For security purposes, this interpreter has static Pogram and Work memory allocations, meaning it has a limit to both code size and memory access size.
	- Change the "#define"s to accomodate larger programs or memory.
- Debug mode: enabled with "-d"
	- Slower and less memory-efficient code execution, but provides more helpful error messages and breakpoints.
	- When active, the asterisk (*) command works as a breakpoint, upon which a small memory dump is displayed and the program ends.


