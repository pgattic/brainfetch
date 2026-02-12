
module PrgExec

let execute (program: Command.Command list) jumpTable =
  let rec executeLoop (program: Command.Command array) (jt: Map<int, int>) pc tape =
    match Array.tryItem pc program with
    | None -> ()
    | Some instr ->
      match instr with
        | Command.IncPtr -> executeLoop program jt (pc+1) (MemTape.nextVal tape)
        | Command.DecPtr -> executeLoop program jt (pc+1) (MemTape.prevVal tape)
        | Command.IncVal -> executeLoop program jt (pc+1) (MemTape.inc tape)
        | Command.DecVal -> executeLoop program jt (pc+1) (MemTape.dec tape)
        | Command.PutChar ->
          System.Console.Write(char(MemTape.getCurr tape))
          executeLoop program jt (pc+1) tape
        | Command.GetChar ->
            let ch =
              match System.Console.Read() with
              | -1 -> 0
              | c -> c
            executeLoop program jt (pc+1) (MemTape.setCurr ch tape)
        | Command.OpenBr ->
          if MemTape.getCurr tape = 0 then
            executeLoop program jt (Map.find pc jt + 1) tape
          else
            executeLoop program jt (pc+1) tape
        | Command.CloseBr ->
          if MemTape.getCurr tape = 0 then
            executeLoop program jt (pc+1) tape
          else
            executeLoop program jt (Map.find pc jt + 1) tape

  executeLoop (List.toArray program) jumpTable 0 MemTape.newMemTape

