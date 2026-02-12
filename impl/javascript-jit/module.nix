{
  perSystem = { pkgs, ... }: {
    devShells.javascript-jit = pkgs.mkShell {
      packages = with pkgs; [
        bun
      ];

      shellHook = ''
        echo "Usage:"
        echo "\`bun main.js [PATH TO FILE]\`"
      '';
    };
  };
}

