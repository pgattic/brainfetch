{
  perSystem = { pkgs, ... }: {
    devShells.zig = pkgs.mkShell {
      packages = with pkgs; [
        zig
      ];
    };
  };
}

