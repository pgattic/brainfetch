{
  description = "BrainF*** Development Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } {
    systems = [
      "x86_64-linux"
      "aarch64-linux"
    ];

    imports = let
      is_module = (inputs.nixpkgs.lib.hasSuffix "module.nix");
    in [
      (inputs.import-tree.filter is_module ./impl)
    ];
  };
}
