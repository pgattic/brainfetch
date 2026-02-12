
[<EntryPoint>]
let main argv =
  match argv with
    [||] ->
      printfn "Please specify a file."
      1
    | args ->
      let filename = args[0]
      try
        let contents = Seq.toList(System.IO.File.ReadAllText filename)
        let parsed = Command.parseCode contents
        let jumpTable = Command.buildJumpTable parsed
        // parsed |> List.iter (fun cmd -> printfn "%A" cmd)
        PrgExec.execute parsed jumpTable
        0
      with
      | :? System.IO.FileNotFoundException ->
        printfn "Error: File not found: %s" filename
        1
      | ex ->
        printfn "Error: %s" ex.Message
        1

