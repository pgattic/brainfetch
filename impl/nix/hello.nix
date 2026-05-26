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
    if head list == x then
      1 + count_repeated x (tail list)
    else
      0;


  # some : Parser a -> Parser [a]
  # Parses one or more occurrences of parser `p`
  some = p: prog: let
    first = p prog;

    many = prog:
      let result = p prog; in
      if result == null then
        { val = []; rem = prog; }
      else
        let rest = many result.rem; in
        {
          val = [ result.val ] ++ rest.val;
          rem = rest.rem;
        };
  in
    if first == null then
      null
    else
      let rest = many first.rem; in
      {
        val = [ first.val ] ++ rest.val;
        rem = rest.rem;
      };

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
in
  parsers.inc (sep "++-")

