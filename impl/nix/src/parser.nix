with builtins; let
  # String -> [String]
  parse_cmds = content:
    filter (ch: elem ch [ "+" "-" ">" "<" "[" "]" "." "," ]) (split "" content);

  # ASTNode:
  # | { type: "Add"; count: Int; }
  # | { type: "Move"; count: Int; }
  # | { type: "PutChar"; }
  # | { type: "GetChar"; }
  # | { type: "Loop"; nodes: [ASTNode]; }
  # | { type: "Zero"; }

  # Parser a: [String] -> { token: a; rest: [String]; }?

  # GENERAL PARSER COMBINATORS

  first_non_null = list:
    if list == [] then
      null
    else
      if head list == null then
        first_non_null (tail list)
      else
        head list;

  # [Parser x] -> Parser x
  parse_choice = parsers: str:
    first_non_null (map (x: x str) parsers);

  # Parser x -> Parser [x]
  parse_many = p: str:
    let parsed = p str; in
      if parsed == null then
        { token = []; rest = str; }
      else
        let parsed_rest = parse_many p parsed.rest; in
          if parsed_rest == null then null else
          { token = [ parsed.token ] ++ parsed_rest.token; rest = parsed_rest.rest; };

  parse_cmd = cmd: val: str:
    if str == [] then null else
    if head str == cmd then { token = val; rest = tail str; } else null;

  # BF PARSERS

  # Parser ASTNode
  parse_add = str: let
    parse_inc = parse_cmd "+" 1;
    parse_dec = parse_cmd "-" (-1);
    parsed = parse_many (parse_choice [ parse_inc parse_dec ]) str;
  in
    if parsed == null then null else
      let sum = builtins.foldl' (acc: x: acc + x) 0 parsed.token; in
        if sum == 0 then null else
        { token = { type = "Add"; count = sum; }; rest = parsed.rest; };

  # Parser ASTNode
  parse_move = str: let
    parse_next = parse_cmd ">" 1;
    parse_prev = parse_cmd "<" (-1);
    parsed = parse_many (parse_choice [ parse_next parse_prev ]) str;
  in
    if parsed == null then null else
      let sum = builtins.foldl' (acc: x: acc + x) 0 parsed.token; in
        if sum == 0 then null else
        { token = { type = "Move"; count = sum; }; rest = parsed.rest; };

  parse_putch = parse_cmd "." { type = "PutChar"; };

  parse_getch = parse_cmd "," { type = "GetChar"; };

  parse_loop = str:
    if str == [] || head str != "[" then null else let
      parsed = bf_parser (tail str);
    in
      if parsed == null then throw "asdf"
      else let
        parseclosed = (parse_cmd "]" {}) parsed.rest;
      in
        if parseclosed == null then throw "unparseable token" else
        { token = { type = "Loop"; nodes = parsed.token; }; rest = parseclosed.rest; };

  bf_parser = let
    parsers = [ parse_add parse_move parse_putch parse_getch parse_loop ];
  in parse_many (parse_choice parsers);

in {
  parse_bf = str: let
    parsed = bf_parser (parse_cmds str);
  in
    if parsed == null || parsed.rest != [] then null else
    parsed.token;
}
