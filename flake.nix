{
  description = "Namecoin-core";

  inputs = {
    utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-21.05";
  };

  outputs = { self, nixpkgs, utils }:
    let
      localOverlay = import ./nix/overlay.nix;

      pkgsForSystem = system: import nixpkgs {
        overlays = [
          localOverlay
        ];
        inherit system;
      };
    in utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" ] (system: rec {
      legacyPackages = pkgsForSystem system;
      packages = utils.lib.flattenTree {
        inherit (legacyPackages) devShell namecoin-core;
      };
      defaultPackage = packages.namecoin-core;
      apps.namecoin-core = utils.lib.mkApp { drv = packages.namecoin-core; };
      hydraJobs = { inherit (legacyPackages) namecoin-core; };
      checks = { inherit (legacyPackages) namecoin-core; };
  }) // {
    overlay = localOverlay;
    overlays = {};
  };
}
