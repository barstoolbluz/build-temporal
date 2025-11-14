{ lib
, stdenv
, fetchFromGitHub
, buildGoModule
, symlinkJoin
}:

let
  # Version information - UPDATE THESE FOR NEW RELEASES
  # Server: https://github.com/temporalio/temporal/releases
  # CLI: https://github.com/temporalio/cli/releases
  serverVersion = "1.29.1";
  cliVersion = "1.5.1";

  # ============================================================================
  # TEMPORAL SERVER
  # ============================================================================

  temporal-server = buildGoModule {
    pname = "temporal-server";
    version = serverVersion;

    src = fetchFromGitHub {
      owner = "temporalio";
      repo = "temporal";
      rev = "v${serverVersion}";
      hash = "sha256-rUm1zHxM0KYPgKpK7w0XLU7aF3H6sECgSe/UtbNdgJM=";
    };

    vendorHash = "sha256-HW2j8swbaWwU1i3udqlT8VyFreML6ZH14zWxF8L5NTQ=";

    # Build flags
    tags = [ "test_dep" ];
    env.CGO_ENABLED = 0;

    ldflags = [
      "-s"  # Strip symbol table
      "-w"  # Strip DWARF debugging info
    ];

    excludedPackages = [ "./build" ];
    doCheck = false;

    # Build server and tools
    subPackages = [
      "cmd/server"
      "cmd/tools/cassandra"
      "cmd/tools/sql"
      "cmd/tools/tdbg"
    ];

    postInstall = ''
      # Rename binaries to match expected names
      mv $out/bin/server $out/bin/temporal-server
      mv $out/bin/cassandra $out/bin/temporal-cassandra-tool
      mv $out/bin/sql $out/bin/temporal-sql-tool

      # Install schema files
      mkdir -p $out/share
      cp -r schema $out/share/
    '';

    meta = with lib; {
      description = "Temporal server and database tools";
      homepage = "https://temporal.io";
      license = licenses.mit;
      platforms = platforms.unix;
    };
  };

  # ============================================================================
  # TEMPORAL CLI
  # ============================================================================

  temporal-cli = buildGoModule {
    pname = "temporal-cli";
    version = cliVersion;

    src = fetchFromGitHub {
      owner = "temporalio";
      repo = "cli";
      rev = "v${cliVersion}";
      hash = "sha256-Y/hTD31WUcVn/OBuNwdhbjDZd36EKbOJRr9PFDKHifg=";
    };

    vendorHash = "sha256-JxjW91aYM8cmekA8um2R60HXGQJK/Koh4yhnozYiMRU=";

    env.CGO_ENABLED = 0;

    ldflags = [
      "-s"
      "-w"
    ];

    doCheck = false;

    # The CLI repo builds a single "temporal" binary
    subPackages = [ "cmd/temporal" ];

    meta = with lib; {
      description = "Temporal CLI for workflow management";
      homepage = "https://temporal.io";
      license = licenses.mit;
      platforms = platforms.unix;
    };
  };

# ============================================================================
# COMBINED PACKAGE
# ============================================================================

in symlinkJoin {
  name = "temporal-${serverVersion}";
  version = serverVersion;

  paths = [
    temporal-server
    temporal-cli
  ];

  meta = with lib; {
    description = "Temporal orchestration platform (server + CLI)";
    longDescription = ''
      Complete Temporal platform including:

      Server (v${serverVersion}):
      - temporal-server: Main orchestration server
      - temporal-sql-tool: SQL database migration tool
      - temporal-cassandra-tool: Cassandra database migration tool
      - tdbg: Debugging and diagnostic utility
      - Database schemas for PostgreSQL, MySQL, SQLite, and Cassandra

      CLI (v${cliVersion}):
      - temporal: Command-line interface for workflow management
    '';
    homepage = "https://temporal.io";
    changelog = "https://github.com/temporalio/temporal/releases/tag/v${serverVersion}";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.unix;
    mainProgram = "temporal-server";
  };
}
