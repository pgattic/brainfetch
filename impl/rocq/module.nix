{
  perSystem = { pkgs, ... }: {
    devShells.rocq = pkgs.mkShell {
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
  };
}

