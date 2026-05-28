with builtins; let
  sep = content:
    filter (ch: elem ch [ "+" "-" ">" "<" "[" "]" "." "," ]) (split "" content);

  take_last = count: list:
    if length list < count then
      null
    else if length list == count then
      list
    else
      take_last count (tail list);

  count_repeated = x: list:
    if length list == 0 then 0 else
    if head list == x then
      1 + count_repeated x (tail list)
    else
      0;

  first_non_null = list:
    if list == [] then
      null
    else
      if head list == null then
        first_non_null (tail list)
      else
        head list;

  # A parser for some thing "a": string -> { val: a; rem: string; }?
  mk_repeat_parser = ch: prog:
    if length prog == 0 then null else
    let count = count_repeated ch prog; in
    if count == 0 then
      null
    else
      { val = { type = ch; inherit count; }; rem = (take_last ((length prog) - count) prog); };

  mk_single_parser = ch: prog:
    if length prog == 0 then null else
    if head prog == ch then
      { val = { type = ch; }; rem = tail prog; }
    else
      null;

  # Parser: prog -> AST
  # Choice: [Parser] -> Parser
  mk_choice = parsers: prog:
    first_non_null (map (x: x prog) parsers);

  # Many: Parser -> Parser
  mk_many = parser: prog:
    let res = parser prog; in
    if res == null then
      []
    else
      [ res.val ] ++ (mk_many parser res.rem);

  parsers = {
    inc = mk_repeat_parser "+";
    dec = mk_repeat_parser "-";
    left = mk_repeat_parser "<";
    right = mk_repeat_parser ">";
    putch = mk_single_parser ".";
    getch = mk_single_parser ",";
  };

  choice = mk_choice (builtins.attrValues parsers);
  many = mk_many choice;
in
  many (sep "<<.++-")

