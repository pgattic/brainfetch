with builtins; let
  parser = import ./parser.nix;
in
  { file }: parser.parse_bf "<<.[-]++-"

