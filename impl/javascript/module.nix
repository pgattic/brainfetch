{
  perSystem = { pkgs, ... }: {
    devShells.javascript = pkgs.mkShell {
      packages = with pkgs; [
        nodejs
      ];

      shellHook = ''
        echo "Usage:"
        echo "\`node main.js [PATH TO FILE]\`"
      '';
    };
  };
}

