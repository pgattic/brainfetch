{
  perSystem = { pkgs, ... }: {
    devShells.lua-jit = pkgs.mkShell {
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

