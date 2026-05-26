with builtins;

let
  # memory = {
  #   left = [];
  #   curr = 0;
  #   right = [];
  # };

  reverse = list:
    if list == [] then [] else (reverse (tail list)) ++ [ (head list) ];

  parse = content:
    filter (ch: elem ch [ "+" "-" ">" "<" "[" "]" "." "," ]) (split "" content);

  take_last = count: list:
    if length list < count then
      null
    else if length list == count then
      list
    else
      take_last count (tail list);

  count_repeated = x: list:
    if head list == x then
      1 + count_repeated x (tail list)
    else
      0;

  # A parser for some thing "a": string -> { val: a; rem: string; }?
  mk_repeat_parser = ch: prog:
    let count = count_repeated ch prog; in
    if count == 0 then
      null
    else
      { val = { type = ch; inherit count; }; rem = (take_last ((length prog) - count) prog); };

  mk_single_parser = ch: prog:
    if head prog == ch then
      { val = { type = ch; }; rem = tail prog; }
    else
      null;

  parsers = {
    inc = mk_repeat_parser "+";
    dec = mk_repeat_parser "-";
    left = mk_repeat_parser "<";
    right = mk_repeat_parser ">";
    putch = mk_single_parser ".";
    getch = mk_single_parser ",";
  };

  tokenize_single_repeatable = program: char:
    if program == [] then
      [ { type = char; count = 1; } ]
    else
      let first = head program; in 
      if (head program).type == char then
        [ { type = first.type; count = first.count + 1; } ] ++ (tail program)
      else
        [ { type = char; count = 1; } ] ++ program;

  tokenize_single = program: char:
    if elem char [ "+" "-" ">" "<" ] then
      tokenize_single_repeatable program char
    else if char == "[" then
      [ { type = "loop"; content = []; } ] ++ program
    else
      [ { type = char; } ] ++ program;

  # tokenize_help = parsed: program:
  tokenize = parsed: reverse (foldl' tokenize_single_repeatable [] parsed);
in
  # { file }: tokenize (parse (readFile file))
  { file }: parsers.inc [ "+" "+" "-" ]

