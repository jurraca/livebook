{
  description = "A flake for Elixir's Livebook.";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs?ref=master;
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }:
    let
    pkgsForSystem = system: import nixpkgs {
        overlays = [ overlay ];
        inherit system;
      };

    overlay = final: prev: rec {
      livebook = with final;
        let
          beamPackages = beam.packagesWith beam.interpreters.erlangR24;
          elixir = beam.packages.erlangR24.elixir_1_12;
          mixNixDeps = import ./deps.nix { inherit lib beamPackages; };
        in beamPackages.mixRelease {
          inherit mixNixDeps;
          pname = "livebook";
          src = ./.;
          version = "0.0.0";
         };
    };
    in utils.lib.eachDefaultSystem (system: rec {
      legacyPackages = pkgsForSystem system;
      packages = utils.lib.flattenTree {
        inherit (legacyPackages) livebook;
      };
      defaultPackage = packages.livebook;
      devShell = self.devShells.${system}.dev;
      devShells = {
        dev = import ./shell.nix {
          pkgs = legacyPackages;
          db_name = "db_dev";
          MIX_ENV = "dev";
        };
        test = import ./shell.nix {
          pkgs = legacyPackages;
          db_name = "db_test";
          MIX_ENV = "test";
        };
        prod = import ./shell.nix {
          pkgs = legacyPackages;
          db_name = "db";
          MIX_ENV = "prod";
        };
      };
      apps.livebook = utils.lib.mkApp { drv = packages.livebook; };
      hydraJobs = { inherit (legacyPackages) livebook; };
      checks = { inherit (legacyPackages) livebook; };
    }) // { overlay = overlay ;};
}
