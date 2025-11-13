{
  description = "Temporal orchestration platform - custom build";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Import the temporal package from our custom expression
        temporal = pkgs.callPackage ./.flox/pkgs/temporal.nix { };

      in {
        # Packages output
        packages = {
          default = temporal;
          temporal = temporal;
        };

        # Apps output - expose all temporal binaries
        apps = {
          # Main server
          temporal-server = {
            type = "app";
            program = "${temporal}/bin/temporal-server";
          };

          # Database tools
          temporal-sql-tool = {
            type = "app";
            program = "${temporal}/bin/temporal-sql-tool";
          };

          temporal-cassandra-tool = {
            type = "app";
            program = "${temporal}/bin/temporal-cassandra-tool";
          };

          # Debugging utility
          tdbg = {
            type = "app";
            program = "${temporal}/bin/tdbg";
          };

          # Default app is the server
          default = {
            type = "app";
            program = "${temporal}/bin/temporal-server";
          };
        };

        # Development shell
        devShells.default = pkgs.mkShell {
          buildInputs = [ temporal ];
        };
      }
    );
}
