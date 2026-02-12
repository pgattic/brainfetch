{
  perSystem = { pkgs, ... }: {
    devShells.haskell = pkgs.mkShell {
      packages = with pkgs; [
        ghc
        cabal-install
        haskell-language-server
      ];
      shellHook = ''
        echo "To build: \`cabal build .\`"
        echo "To run: \`cabal run . -- [PATH TO FILE]\`"
      '';
    };
  };
}

