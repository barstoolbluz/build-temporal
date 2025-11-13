{ lib
, stdenv
, fetchFromGitHub
, buildGoModule
}:

let
  # Version information - UPDATE THESE FOR NEW RELEASES
  # Find releases at: https://github.com/temporalio/temporal/releases
  version = "1.29.1";

  # Source code from GitHub
  # When updating version, set hash = "" and run `flox build` to get correct hash
  src = fetchFromGitHub {
    owner = "temporalio";
    repo = "temporal";
    rev = "v${version}";
    hash = "sha256-rUm1zHxM0KYPgKpK7w0XLU7aF3H6sECgSe/UtbNdgJM=";
  };

in buildGoModule {
  pname = "temporal";
  inherit version src;

  # Go module dependencies hash
  # When updating version, set vendorHash = "" and run `flox build` to get correct hash
  vendorHash = "sha256-HW2j8swbaWwU1i3udqlT8VyFreML6ZH14zWxF8L5NTQ=";

  # Build flags
  # - Disable grpc modules to reduce binary size
  # - Add test_dep for additional testing utilities
  tags = [ "test_dep" ];

  # Disable CGO for static binary compilation
  env.CGO_ENABLED = 0;

  # Linker flags to strip debugging symbols and reduce size
  ldflags = [
    "-s"  # Strip symbol table
    "-w"  # Strip DWARF debugging info
  ];

  # Exclude build directory from source tree
  # This directory contains build artifacts and CI configurations
  excludedPackages = [ "./build" ];

  # Skip tests - temporal has extensive integration tests that:
  # - Require external services (Cassandra, PostgreSQL, Elasticsearch)
  # - Take significant time to run
  # - Are tested upstream in CI/CD
  doCheck = false;

  # Specify which subpackages to build
  # buildGoModule will automatically install binaries to $out/bin
  subPackages = [
    "cmd/server"           # Creates "server" binary
    "cmd/tools/cassandra"  # Creates "cassandra" binary
    "cmd/tools/sql"        # Creates "sql" binary
    "cmd/tools/tdbg"       # Creates "tdbg" binary
  ];

  # Post-install: rename binaries and add schema files
  postInstall = ''
    # Rename binaries to match expected names
    mv $out/bin/server $out/bin/temporal-server
    mv $out/bin/cassandra $out/bin/temporal-cassandra-tool
    mv $out/bin/sql $out/bin/temporal-sql-tool
    # tdbg is already correct

    # Install schema files for database initialization
    mkdir -p $out/share
    cp -r schema $out/share/
  '';

  # Metadata
  meta = with lib; {
    description = "Temporal service (orchestration platform)";
    longDescription = ''
      Temporal is a microservice orchestration platform which enables developers
      to build scalable applications without sacrificing productivity or reliability.

      This package includes:
      - temporal-server: Main server binary
      - temporal-sql-tool: SQL database migration tool
      - temporal-cassandra-tool: Cassandra database migration tool
      - tdbg: Debugging and diagnostic utility
      - Database schemas for PostgreSQL, MySQL, SQLite, and Cassandra
    '';
    homepage = "https://temporal.io";
    changelog = "https://github.com/temporalio/temporal/releases/tag/v${version}";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.unix;
    mainProgram = "temporal-server";
  };
}
