{
  perSystem = { pkgs, ... }: {
    devShells.python-jit = pkgs.mkShell {
      packages = with pkgs; [
        python3
        python314Packages.readchar
      ];

      shellHook = ''
        echo "Usage:"
        echo "\`python3 main.py [PATH TO FILE]\`"
      '';
    };
  };
}

