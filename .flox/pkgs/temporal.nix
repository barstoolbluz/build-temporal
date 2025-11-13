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
    hash = "sha256-8hl8FJ9TRJk6A/qPa2O6CsB7Y4VX7uM4XwXK8wX3VmY=";
  };

in buildGoModule {
  pname = "temporal";
  inherit version src;

  # Go module dependencies hash
  # When updating version, set vendorHash = "" and run `flox build` to get correct hash
  vendorHash = "sha256-HW2j8swbaWwU1i3udqlT8VyFreML6ZH14zWxF8L5NTQ=";

  # Disable CGO for static binary compilation
  CGO_ENABLED = 0;

  # Build flags
  # - Disable grpc modules to reduce binary size
  # - Add test_dep for additional testing utilities
  tags = [ "test_dep" ];

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

  # Installation phase
  # Temporal builds multiple binaries for different purposes
  installPhase = ''
    runHook preInstall

    # Create output directories
    mkdir -p $out/bin
    mkdir -p $out/share/schema

    # Install server binary
    install -Dm755 temporal-server $out/bin/temporal-server

    # Install database tools
    install -Dm755 temporal-cassandra-tool $out/bin/temporal-cassandra-tool
    install -Dm755 temporal-sql-tool $out/bin/temporal-sql-tool

    # Install debugging utility
    install -Dm755 tdbg $out/bin/tdbg

    # Install schema files for database initialization
    cp -r schema $out/share/

    runHook postInstall
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
