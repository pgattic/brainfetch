{
  perSystem = { pkgs, ... }: {
    devShells.rust-cranelift = pkgs.mkShell {
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

