# Using build-temporal with Flox

This document explains how to use the build-temporal package with Flox.

## Quick Start

### Building Locally

```bash
# Clone the repository
git clone https://github.com/barstoolbluz/build-temporal.git
cd build-temporal

# Activate the build environment
flox activate

# Build the package
flox build

# The result is in ./result/
./result/bin/temporal-server --version
```

### Using in Your Environment

After publishing to FloxHub, you can use it in any Flox environment:

```toml
# In your .flox/env/manifest.toml
[install]
temporal.pkg-path = "temporal"  # From your catalog
```

Or reference directly from GitHub:

```toml
[install]
temporal.pkg-path = "github:barstoolbluz/build-temporal#temporal"
```

## Publishing to FloxHub

Publishing makes your custom-built Temporal available across all your environments:

```bash
# From the build-temporal directory
flox publish

# Now available in your catalog
flox search temporal
```

**Important:** Publishing replaces the previous version. To maintain multiple versions:
- Use git tags (e.g., `v1.29.1`, `v1.30.0`)
- Reference specific tags: `github:barstoolbluz/build-temporal?ref=v1.29.1#temporal`

## Integration with temporal-headless

The build-temporal package works perfectly with temporal-headless environment:

```toml
# In temporal-headless/.flox/env/manifest.toml
[install]
temporal.pkg-path = "github:barstoolbluz/build-temporal#temporal"

[include]
environments = [
  { remote = "barstoolbluz/postgres-headless" }
]
```

This gives you:
- ✅ Latest Temporal version (your custom build)
- ✅ PostgreSQL support (via composition)
- ✅ Full control over Temporal version
- ✅ Reproducible deployments

## Building Different Versions

### Build a Specific Tag

```bash
# Clone with specific tag
git clone --branch v1.29.1 https://github.com/barstoolbluz/build-temporal.git
cd build-temporal
flox build
```

### Reference Specific Version in Flake

```toml
[install]
# Use specific git ref
temporal.pkg-path = "github:barstoolbluz/build-temporal?ref=v1.29.1#temporal"
```

## Development Workflow

### Making Changes

```bash
# Clone and enter environment
git clone https://github.com/barstoolbluz/build-temporal.git
cd build-temporal
flox activate

# Edit the build expression
vim .flox/pkgs/temporal.nix

# Test the build
flox build

# Verify
./result/bin/temporal-server --version
```

### Testing Locally Before Publishing

```bash
# Create a test environment
mkdir /tmp/test-temporal
cd /tmp/test-temporal
flox init

# Edit manifest to use local build
flox edit
# Add: temporal.pkg-path = "path:/path/to/build-temporal#temporal"

# Activate and test
flox activate
temporal-server --version
```

## Flox Commands Reference

### In build-temporal Directory

```bash
# Activate build environment (adds go, git, make)
flox activate

# Build the package
flox build

# Clean build outputs
rm -rf result result-*

# Show package info
nix flake show

# Check flake
nix flake check
```

### Using Published Package

```bash
# Search for package
flox search temporal

# Install in current environment
flox install temporal

# Show package details
flox show temporal

# Remove package
flox uninstall temporal
```

## Publishing Workflow

```bash
# 1. Build and test locally
flox build
./result/bin/temporal-server --version

# 2. Commit changes
git add .
git commit -m "Update to vX.Y.Z"
git tag vX.Y.Z
git push origin main --tags

# 3. Publish to FloxHub
flox publish

# 4. Verify publication
flox search temporal
```

## Catalog Management

### Your Personal Catalog

When you `flox publish`, the package goes to your personal catalog:

```bash
# List packages in your catalog
flox search

# Show specific package
flox show temporal
```

### Using Across Machines

Once published, any machine with Flox can use it:

```bash
# On another machine
flox init myproject
cd myproject
flox install temporal

# Or in manifest.toml
[install]
temporal.pkg-path = "temporal"
```

## Advanced Usage

### Custom Build Flags

Edit `.flox/pkgs/temporal.nix` to customize:

```nix
# Add custom build tags
tags = [ "test_dep" "custom_feature" ];

# Modify linker flags
ldflags = [
  "-s"
  "-w"
  "-X main.version=${version}"
];

# Enable CGO if needed
CGO_ENABLED = 1;
```

### Platform-Specific Builds

```bash
# Build for specific platform
nix build .#temporal --system x86_64-linux

# Build for multiple platforms (requires remote builders)
nix build .#temporal --system aarch64-darwin
```

### Combining with Other Packages

```toml
# In your environment
[install]
temporal.pkg-path = "github:barstoolbluz/build-temporal#temporal"
postgres.pkg-path = "github:barstoolbluz/build-postgres#postgres"
redis.pkg-path = "redis"

# All work together in one environment
```

## Troubleshooting

### Build Fails in Flox

```bash
# Activate environment to debug
flox activate

# Try building with Nix directly
nix build .#temporal --show-trace

# Check logs
nix log .#temporal
```

### Package Not Found After Publishing

```bash
# Refresh catalog
flox search --refresh

# Check publication status
flox show temporal
```

### Version Conflicts

If you have multiple temporal sources:

```toml
# Be explicit about source
[install]
temporal-custom.pkg-path = "github:barstoolbluz/build-temporal#temporal"
temporal-nixpkgs.pkg-path = "temporal"  # From nixpkgs

# Use aliases to avoid conflicts
```

## Comparison: Flox vs Nix

| Operation | Flox Command | Nix Command |
|-----------|--------------|-------------|
| Build | `flox build` | `nix build .#temporal` |
| Run | `flox activate -- temporal-server` | `nix run .#temporal-server` |
| Shell | `flox activate` | `nix develop` |
| Install | `flox install temporal` | N/A (flox-specific) |
| Publish | `flox publish` | N/A (flox-specific) |

Both work! Flox adds catalog and environment management on top of Nix.

## Best Practices

### Version Pinning

```toml
# Pin to specific version via git ref
[install]
temporal.pkg-path = "github:barstoolbluz/build-temporal?ref=v1.29.1#temporal"
```

### Testing Before Publishing

Always test locally before publishing:

```bash
# 1. Build
flox build

# 2. Test all binaries
./result/bin/temporal-server --version
./result/bin/temporal-sql-tool --version
./result/bin/temporal-cassandra-tool --version
./result/bin/tdbg --version

# 3. Test in real environment
cd /path/to/temporal-headless
flox edit  # Update to use new build
flox activate -s
# Verify services work
```

### Documentation

Keep version info updated:
- README.md: Current version badge
- BUILD_VERSIONS.md: Update history
- Git tags: Match versions

## Integration Examples

### CI/CD Pipeline

```yaml
# .github/workflows/ci.yml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: DeterminateSystems/nix-installer-action@main
      - uses: DeterminateSystems/magic-nix-cache-action@main

      - name: Build temporal
        run: nix build .#temporal

      - name: Test binaries
        run: |
          ./result/bin/temporal-server --version
          ./result/bin/temporal-sql-tool --version
```

### Docker Container

```dockerfile
FROM nixos/nix
RUN nix build github:barstoolbluz/build-temporal#temporal
RUN cp -r /nix/store/*-temporal/bin/* /usr/local/bin/
CMD ["temporal-server", "start"]
```

### Development Environment

```toml
# .flox/env/manifest.toml for Temporal development
[install]
temporal.pkg-path = "github:barstoolbluz/build-temporal#temporal"
go.pkg-path = "go"
postgresql.pkg-path = "postgresql"
python3.pkg-path = "python3"

[vars]
TEMPORAL_HOME = "$FLOX_ENV_CACHE/temporal-dev"

[hook]
on-activate = '''
  echo "Temporal development environment ready"
  echo "Server: temporal-server"
  echo "Tools: temporal-sql-tool, temporal-cassandra-tool, tdbg"
'''
```

## Getting Help

- **Build issues**: See BUILD_VERSIONS.md
- **Flox questions**: https://flox.dev/docs
- **Temporal questions**: https://docs.temporal.io
- **Repository issues**: https://github.com/barstoolbluz/build-temporal/issues
