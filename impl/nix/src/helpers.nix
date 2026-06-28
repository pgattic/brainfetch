with builtins; let
  repeat = x: fn: input:
    if x <= 0 then input else
      repeat (x - 1) fn (fn input);

  asciiCodeToString = let
    asciiTable = "          \t\n  \r                  !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~ ";
  in code: builtins.substring code 1 asciiTable;

  mod = x: y:
    let
      rem = x - (x / y * y);
    in
      if rem < 0 then rem + y else rem;

  first_non_null = list:
    if list == [] then
      null
    else
      if head list == null then
        first_non_null (tail list)
      else
        head list;

in {
  inherit repeat asciiCodeToString mod first_non_null;
}
