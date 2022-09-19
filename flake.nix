{
  description = "Namecoin-core";

  inputs = {
    utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-21.05";
  };

  outputs = { self, nixpkgs, utils }:
    let
      localOverlay = final: prev: {
        namecoin-core = prev.callPackage ./nix/namecoin-core.nix { };

        devShell = final.namecoin-core;
      };

      pkgsForSystem = system:
        import nixpkgs {
          overlays = [ localOverlay ];
          inherit system;
        };
    in utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" ]
    (system: rec {
      legacyPackages = pkgsForSystem system;
      packages = utils.lib.flattenTree {
        inherit (legacyPackages) devShell namecoin-core;
        default = legacyPackages.namecoin-core;
      };
      apps.namecoin-core = utils.lib.mkApp { drv = packages.namecoin-core; };
      hydraJobs = { inherit (legacyPackages) namecoin-core; };
      checks = { inherit (legacyPackages) namecoin-core; };
    }) // {
      nixosModules.namecoin-core = { pkgs, lib, config, ... }:
        with lib;
        let cfg = config.services.namecoin-core;
        in {
          options = {
            services.namecoin-core = {
              enable = mkOption {
                type = types.bool;
                default = false;
              };
            };
          };
          config = mkIf cfg.enable {
            nixpkgs.overlays = [ localOverlay ];

            systemd.packages = [ pkgs.namecoin-core ];

            systemd.services.namecoin-core = {
              path = [ pkgs.namecoin-core ];
              description = "Namecoin Core daemon.";

              serviceConfig = {
                Type = "simple";
                ExecStart = "${pkgs.namecoin-core}/bin/namecoind";
                wantedBy = [ "default.target" ];
              };
            };
          };
        };
      overlays.default = localOverlay;
    };
}
