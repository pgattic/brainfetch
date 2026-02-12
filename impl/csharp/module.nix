{
  perSystem = { pkgs, ... }: {
    devShells.csharp = pkgs.mkShell {
      packages = with pkgs; [
        dotnet-sdk_9
      ];
      shellHook = ''
        echo "To build: \`dotnet build --configuration Release\`"
        echo "To run: \`dotnet run --configuration Release -- [FILE.bf]\`"
      '';
    };
  };
}

