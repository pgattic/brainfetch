{
  description = "BrainF*** in Rocq (Coq)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            coq
            rocqPackages.stdlib
            coqPackages.vscoq-language-server
          ];

          # Optional: helps some tools find libraries
          COQPATH = ".:./_build/default";
          ROCQPATH = ".:./_build/default";

          shellHook = ''
            echo "To compile this project:"
            echo "  - \`rocq makefile -f _RocqProject -o Makefile\`"
            echo "  - \`make\`"
          '';
        };
      });
}

