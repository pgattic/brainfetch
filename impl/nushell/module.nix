{
  perSystem = { pkgs, ... }: {
    devShells.nushell = pkgs.mkShell {
      packages = with pkgs; [
        nushell
      ];

      shellHook = ''
      '';
    };
  };
}

