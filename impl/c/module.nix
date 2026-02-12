{
  perSystem = { pkgs, ... }: {
    devShells.c = pkgs.mkShell {
      packages = with pkgs; [
        gcc
        gnumake
      ];
      shellHook = ''
        echo "To build: \`make\`"
        echo "To run: \`./brainfetch [PATH TO FILE]\`"
      '';
    };
  };
}

