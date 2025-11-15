# build-temporal

Custom Nix/Flox build for [Temporal](https://temporal.io) orchestration platform, tracking upstream releases from [temporalio/temporal](https://github.com/temporalio/temporal).

## Overview

This repository provides a reproducible Nix build for Temporal server and tools. It follows the same pattern as [build-dagster](https://github.com/barstoolbluz/build-dagster) for version tracking and publishing.

**Current version:** 1.29.1

## What's Included

This build provides the following binaries:

- **temporal-server** - Main orchestration server
- **temporal-sql-tool** - SQL database migration and management
- **temporal-cassandra-tool** - Cassandra database migration and management
- **tdbg** - Temporal debugging and diagnostic utility
- **Schema files** - Database schemas for PostgreSQL, MySQL, SQLite, Cassandra

**Note:** The `temporal` CLI is in a separate repository ([temporalio/cli](https://github.com/temporalio/cli)) and not included here. See [build-temporal-cli](https://github.com/barstoolbluz/build-temporal-cli) for that.

## Quick Start

### Using Nix Flakes

```bash
# Build
nix build github:barstoolbluz/build-temporal

# Run server
nix run github:barstoolbluz/build-temporal#temporal-server -- --version

# Run SQL tool
nix run github:barstoolbluz/build-temporal#temporal-sql-tool -- --help

# Development shell
nix develop github:barstoolbluz/build-temporal
```

### Using Flox

```bash
# Clone and enter environment
git clone https://github.com/barstoolbluz/build-temporal.git
cd build-temporal
flox activate

# Build the package
flox build

# Test the build
./result/bin/temporal-server --version
```

### Using in Your Flox Environment

```toml
# In your .flox/env/manifest.toml
[install]
temporal.pkg-path = "github:barstoolbluz/build-temporal#temporal"
```

Or use the published catalog version (after publishing):

```toml
[install]
temporal.pkg-path = "temporal"  # From barstoolbluz catalog
```

## Architecture

Following the build-dagster pattern, this repository uses:

- **Single Nix expression** (`.flox/pkgs/temporal.nix`) - All build logic in one file
- **Flake interface** (`flake.nix`) - Expose packages and apps
- **Flox manifest** (`.flox/env/manifest.toml`) - Build dependencies

### Build Process

The Nix expression:
1. Fetches source from GitHub (`temporalio/temporal`)
2. Builds using Go's module system (`buildGoModule`)
3. Compiles 4 binaries with CGO disabled
4. Installs schema files for database initialization
5. Creates a single derivation with all components

## Updating Versions

See [BUILD_VERSIONS.md](BUILD_VERSIONS.md) for detailed update process.

**Quick version:**

1. Check latest release: https://github.com/temporalio/temporal/releases
2. Edit `.flox/pkgs/temporal.nix`:
   - Update `version = "X.Y.Z"`
   - Set `hash = ""` and `vendorHash = ""`
3. Run `flox build` - it will fail with correct hashes
4. Update hashes in `temporal.nix`
5. Run `flox build` again - should succeed
6. Test: `./result/bin/temporal-server --version`
7. Commit and push
8. Publish: `flox publish`

## Why This Exists

The nixpkgs `temporal` package exists and works fine in nix-shell, but has compatibility issues when used with Flox:
- **Flox-specific TLS conflict** - Installing both `temporal@1.29.1` and `temporal-cli@1.5.1` from nixpkgs in the same Flox environment causes a glibc thread-local storage error (this does not affect nix-shell):
  ```
  Inconsistency detected by ld.so: ../elf/dl-tls.c: 617: _dl_allocate_tls_init:
  Assertion `listp->slotinfo[cnt].gen <= GL(dl_tls_generation)' failed!
  ```
- **Combined package** - This build combines both server and CLI into a single package, avoiding composition issues
- **Update lag** - nixpkgs may lag behind upstream releases
- **Version control** - Need specific versions for production
- **Custom builds** - May want patches or build flag modifications

This repo gives you:
- ✅ **Working build** - No TLS conflicts, combines server + CLI
- ✅ Track latest Temporal releases
- ✅ Pin to specific versions
- ✅ Reproducible builds
- ✅ Fast updates (just edit version + hashes)
- ✅ Publish to your Flox catalog
- ✅ Compose into environments

## Comparison: nixpkgs vs build-temporal

| Feature | nixpkgs | build-temporal |
|---------|---------|----------------|
| Temporal version | May lag | Track upstream |
| Server + CLI | Separate packages | Combined in one |
| nix-shell compatibility | ✅ Works | ✅ Works |
| Flox compatibility | ❌ TLS conflict when combined | ✅ Works correctly |
| Update speed | Depends on maintainers | Immediate |
| Customization | Fork nixpkgs | Edit one file |
| Version pinning | Specific nixpkgs rev | Direct version field |
| Publishing | N/A | `flox publish` |

**Recommendation:**
- For **nix-shell**: Either works fine
- For **Flox environments**: Use build-temporal to avoid TLS conflicts

## Project Structure

```
build-temporal/
├── .flox/
│   ├── env/
│   │   └── manifest.toml      # Build environment deps (go, git, make)
│   └── pkgs/
│       └── temporal.nix        # Main build expression
├── flake.nix                   # Nix flake interface
├── flake.lock                  # Locked flake inputs
├── default.nix                 # Non-flake compatibility (optional)
├── README.md                   # This file
├── BUILD_VERSIONS.md           # Version update guide
└── .gitignore                  # Ignore build results

```

## Binaries Explained

### temporal-server
Main server binary. Runs the complete Temporal orchestration platform including:
- Frontend service (gRPC API on port 7233)
- History service (workflow execution)
- Matching service (task dispatching)
- Worker service (background processing)

### temporal-sql-tool
Database migration and schema management for SQL backends:
- PostgreSQL
- MySQL
- SQLite

**Usage:**
```bash
temporal-sql-tool --ep localhost --port 5432 --plugin postgres create-database
temporal-sql-tool --ep localhost --port 5432 --plugin postgres setup-schema -v 0.0
```

### temporal-cassandra-tool
Database migration and schema management for Cassandra backend.

**Usage:**
```bash
temporal-cassandra-tool --ep 127.0.0.1 create-keyspace -k temporal
temporal-cassandra-tool --ep 127.0.0.1 -k temporal setup-schema -v 0.0
```

### tdbg
Debugging and diagnostic utility for Temporal workflows and services.

## Dependencies

**Build time:**
- Go 1.21+ toolchain
- Git (for fetching source)
- Make (for build process)

**Runtime:**
- None (statically linked Go binary with CGO_ENABLED=0)
- Database (SQLite, PostgreSQL, MySQL, or Cassandra)

## Platform Support

Builds on:
- ✅ x86_64-linux
- ✅ aarch64-linux (ARM64 Linux)
- ✅ x86_64-darwin (Intel macOS)
- ✅ aarch64-darwin (Apple Silicon macOS)

## Related Projects

- [temporalio/temporal](https://github.com/temporalio/temporal) - Upstream source
- [temporalio/cli](https://github.com/temporalio/cli) - Temporal CLI (separate)
- [build-dagster](https://github.com/barstoolbluz/build-dagster) - Similar build pattern for Dagster
- [build-prefect](https://github.com/barstoolbluz/build-prefect) - Similar build pattern for Prefect

## Usage with temporal-headless

This build can be used with [temporal-headless](https://github.com/barstoolbluz/temporal-headless) environment:

```toml
# In temporal-headless/.flox/env/manifest.toml
[install]
temporal.pkg-path = "github:barstoolbluz/build-temporal#temporal"

# Or after publishing to catalog:
temporal.pkg-path = "temporal"  # From your catalog
```

## Publishing to FloxHub

After building and testing:

```bash
# Ensure you're logged in
flox auth login

# Publish to your catalog
flox publish

# Others can now use:
# flox install temporal
```

## Maintenance

This repository tracks upstream Temporal releases. When a new version is released:

1. Update `temporal.nix` with new version
2. Update hashes (see BUILD_VERSIONS.md)
3. Build and test
4. Commit and push
5. Publish to catalog

**Automation potential:**
- GitHub Actions to check for new releases
- Automated hash updates
- CI builds for all platforms

## License

This build configuration is provided as-is. Temporal itself is MIT licensed.

## Contributing

Improvements welcome! Common contributions:
- Update to latest Temporal version
- Add automation for version updates
- Improve build flags or optimization
- Add additional helper scripts
- Platform-specific fixes

## Troubleshooting

### TLS Error with nixpkgs temporal in Flox

If you see this error when using nixpkgs `temporal` and `temporal-cli` together **in a Flox environment**:
```
Inconsistency detected by ld.so: ../elf/dl-tls.c: 617: _dl_allocate_tls_init:
Assertion `listp->slotinfo[cnt].gen <= GL(dl_tls_generation)' failed!
```

**Cause:** This is a glibc thread-local storage conflict between the two separate nixpkgs packages when installed together in any Flox environment (whether single or composed). This issue is specific to how Flox manages package environments and does not affect plain nix-shell usage.

**Note:** The nixpkgs packages work fine in `nix-shell`:
```bash
# This works fine
nix-shell -p temporal temporal-cli --run "temporal-server --version"
```

**Solution for Flox:** Use this custom build instead:
```toml
[install]
temporal.pkg-path = "barstoolbluz/temporal"
# Provides both server and CLI without conflicts
```

**Validation:**
```bash
# Test that it works in Flox
flox activate -- bash -c 'temporal-server --version && temporal --version'
```

### Build Fails with Hash Mismatch

If `flox build` fails with a hash mismatch, this is normal during version updates:
1. The error message will show the correct hash
2. Copy the hash from the error message
3. Update `.flox/pkgs/temporal.nix` with the correct hash
4. Run `flox build` again

See [BUILD_VERSIONS.md](BUILD_VERSIONS.md) for detailed hash update process.

## Support

For Temporal usage questions, see:
- [Temporal Documentation](https://docs.temporal.io/)
- [Temporal Community Forum](https://community.temporal.io/)
- [Temporal GitHub Issues](https://github.com/temporalio/temporal/issues)

For build-temporal issues:
- [Open an issue](https://github.com/barstoolbluz/build-temporal/issues)
