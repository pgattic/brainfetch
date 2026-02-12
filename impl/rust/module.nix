{
  perSystem = { pkgs, ... }: {
    devShells.rust = pkgs.mkShell {
      packages = with pkgs; [
        cargo
        rustc
        rustfmt
        rust-analyzer
        rustPackages.clippy
      ];
    };
  };
}

