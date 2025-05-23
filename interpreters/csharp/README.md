
# C# Implementation

BrainF*** Interpreter written in C#

By Preston Corless

Not super fast at the moment, but it does run. Kind of hastily thrown together, haha. C# doesn't have tagged union types, which are what I rely on in Rust and Zig. I'll have to learn about the best approach to take for C#'s case.

## Usage

`dotnet run --configuration Release -- [FILE.bf]`

## Performance

- Can run `/bf/mandelbrot.bf` in 4:23.246
- Can run `/bf/hanoi.bf` in 8.517

