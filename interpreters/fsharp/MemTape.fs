
module MemTape

type MemTape = {
  Left: int list;
  Curr: int;
  Right: int list
}

let newMemTape = { Left = []; Curr = 0; Right = [] }

let inc tape = { tape with Curr = (tape.Curr + 1) % 256 }
let dec tape = { tape with Curr = (tape.Curr + 255) % 256 }

let nextVal tape =
  let newLeft = tape.Curr :: tape.Left
  match tape.Right with
  | next :: rest -> { Left = newLeft; Curr = next; Right = rest }
  | [] -> { Left = newLeft; Curr = 0; Right = [] }

let prevVal tape =
  let newRight = tape.Curr :: tape.Right
  match tape.Left with
  | next :: rest -> { Left = rest; Curr = next; Right = newRight }
  | [] -> { Left = []; Curr = 0; Right = newRight }

let getCurr tape = tape.Curr
let setCurr value tape = { tape with Curr = value }

