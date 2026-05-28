{
  perSystem = { pkgs, ... }: {
    devShells.nix = pkgs.mkShell {
      packages = [
        pkgs.nix
        pkgs.nil
      ];

      shellHook = ''
        echo "Usage:"
        echo "\`nix-instantiate --strict --eval src/brainfetch.nix --argstr file "/absolute/path/to/file.bf"\`"
        echo ""
        echo "Note: Nix has a hard time with relative paths from strings, absolute path is required"
      '';
    };
  };
}
