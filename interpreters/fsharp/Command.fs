
module Command

type Command =
  | IncPtr
  | DecPtr
  | IncVal
  | DecVal
  | PutChar
  | GetChar
  | OpenBr
  | CloseBr

let parseCode code =
  code
  |> List.choose (function
      | '>' -> Some IncPtr
      | '<' -> Some DecPtr
      | '+' -> Some IncVal
      | '-' -> Some DecVal
      | '.' -> Some PutChar
      | ',' -> Some GetChar
      | '[' -> Some OpenBr
      | ']' -> Some CloseBr
      | _ -> None)

let buildJumpTable (program: Command list) =
  let rec loop i stack map =
    match program |> List.tryItem i with
    | None -> map // "Done" condition
    | Some OpenBr -> loop (i + 1) (i :: stack) map
    | Some CloseBr ->
        match stack with
        | [] -> failwithf "Error: unmatched ']' at %d" i
        | openIdx :: rest ->
            loop (i + 1) rest (map |> Map.add openIdx i |> Map.add i openIdx)
    | Some _ -> loop (i + 1) stack map
  loop 0 [] Map.empty


