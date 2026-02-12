{
  perSystem = { pkgs, ... }: {
    devShells.lua = pkgs.mkShell {
      packages = with pkgs; [
        luajit
      ];

      shellHook = ''
        echo "Usage:"
        echo "\`luajit brainfetch.lua [PATH TO FILE]\`"
      '';
    };
  };
}

