with builtins; let
  parser = import ./parser.nix;
  interp = import ./interp.nix;
in
  { file }: interp.interp (parser.parse_bf (readFile file))

