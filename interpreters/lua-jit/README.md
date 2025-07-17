
# Lua Implementation

BrainF*** JIT compiler written in Lua

By Preston Corless

NOTE that this doesn't mean I'm just using LuaJIT. It means I am building a Lua program from the BrainF*** code and executing it directly using Lua's `loadstring` function

## Usage

`luajit brainfetch.lua path/to/file.bf`

## Performance

- Can run `/bf/mandelbrot.bf` in 4.142
- Can run `/bf/hanoi.bf` in 0.652

