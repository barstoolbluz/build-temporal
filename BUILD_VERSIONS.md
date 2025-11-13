# Updating Temporal Versions

This document describes the process for updating the Temporal build to a new version.

## Overview

The build process uses Nix's content-addressed store, which requires knowing the exact hash of downloaded sources. When updating versions, we need to update both the version number and the source hashes.

## Quick Update Process

### 1. Find the Latest Release

Check the Temporal releases page:
- https://github.com/temporalio/temporal/releases

Example: Updating from `1.29.1` to `1.30.0`

### 2. Edit `.flox/pkgs/temporal.nix`

Update **3 locations** in the file:

**Location 1: Version declaration (line ~11)**
```nix
version = "1.30.0";  # Change from 1.29.1
```

**Location 2: Source hash (lines ~16-20)**
```nix
src = fetchFromGitHub {
  owner = "temporalio";
  repo = "temporal";
  rev = "v${version}";  # This automatically uses the version above
  hash = "";  # SET TO EMPTY STRING - will be filled in step 3
};
```

**Location 3: Vendor hash (line ~30)**
```nix
vendorHash = "";  # SET TO EMPTY STRING - will be filled in step 3
```

### 3. Obtain Correct Hashes

Nix will tell you the correct hashes when the build fails.

**Step 3a: Get source hash**

Run the build:
```bash
flox build
```

You'll see an error like:
```
error: hash mismatch in fixed-output derivation '/nix/store/...':
  specified: sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
  got:       sha256-8hl8FJ9TRJk6A/qPa2O6CsB7Y4VX7uM4XwXK8wX3VmY=
```

**Copy the `got:` hash** and update `.flox/pkgs/temporal.nix`:
```nix
hash = "sha256-8hl8FJ9TRJk6A/qPa2O6CsB7Y4VX7uM4XwXK8wX3VmY=";
```

**Step 3b: Get vendor hash**

Run the build again:
```bash
flox build
```

You'll see a different error:
```
error: hash mismatch in fixed-output derivation '/nix/store/...go-modules':
  specified: sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
  got:       sha256-HW2j8swbaWwU1i3udqlT8VyFreML6ZH14zWxF8L5NTQ=
```

**Copy the `got:` hash** and update `.flox/pkgs/temporal.nix`:
```nix
vendorHash = "sha256-HW2j8swbaWwU1i3udqlT8VyFreML6ZH14zWxF8L5NTQ=";
```

### 4. Build and Test

**Build:**
```bash
flox build
```

Should complete successfully, creating `./result/` directory.

**Test the binaries:**
```bash
# Check version
./result/bin/temporal-server --version

# Check help
./result/bin/temporal-server --help

# Verify other tools
./result/bin/temporal-sql-tool --version
./result/bin/temporal-cassandra-tool --version
./result/bin/tdbg --version
```

**Test in a dev shell:**
```bash
nix develop
temporal-server --version
```

### 5. Commit and Publish

**Commit changes:**
```bash
git add .flox/pkgs/temporal.nix
git commit -m "Update Temporal to v1.30.0"
git push
```

**Update flake.lock:**
```bash
nix flake update
git add flake.lock
git commit -m "Update flake.lock for v1.30.0"
git push
```

**Publish to FloxHub:**
```bash
flox publish
```

This replaces the previous version in your catalog.

## Detailed Explanation

### Why Two Hashes?

**Source hash (`hash`):**
- Verifies the GitHub source tarball
- Ensures reproducibility - same version always gives same source
- Changes with every new Temporal release

**Vendor hash (`vendorHash`):**
- Verifies Go module dependencies
- Go projects use external dependencies (vendored modules)
- Changes when dependencies are updated (even if version stays same)

### Alternative: Using `nix-prefetch-url`

Instead of empty hashes, you can pre-fetch:

**For source hash:**
```bash
nix-prefetch-url --unpack \
  https://github.com/temporalio/temporal/archive/refs/tags/v1.30.0.tar.gz
```

**For vendor hash:**
This is harder to pre-calculate. The empty-string method is easier.

### Automation Ideas

**Check for new releases:**
```bash
# Using GitHub API
curl -s https://api.github.com/repos/temporalio/temporal/releases/latest \
  | jq -r '.tag_name'
```

**Future enhancement:**
- GitHub Actions workflow to check for releases
- Automatically open PR with version updates
- CI builds to verify all platforms

## Troubleshooting

### Build fails with "unknown revision"

The release doesn't exist on GitHub. Check:
```bash
curl -I https://github.com/temporalio/temporal/archive/refs/tags/v1.30.0.tar.gz
```

Should return `200 OK`, not `404 Not Found`.

### Build fails with Go compilation errors

Possible causes:
1. **Go version too old** - Check `go.mod` in upstream repo for minimum Go version
2. **Breaking changes** - New version may need build flag adjustments
3. **Platform incompatibility** - Some versions may not build on certain platforms

Check the upstream CI configuration for build requirements.

### Vendor hash keeps changing

This can happen if:
1. Upstream dependencies were updated
2. You're on a different platform (shouldn't happen with Nix, but rare edge case)
3. Network issues during fetch

Solution: Clear the Nix store and rebuild:
```bash
nix-collect-garbage
flox build
```

### Build succeeds but binaries crash

Test with:
```bash
./result/bin/temporal-server --version
```

If it crashes:
1. Check build flags - maybe CGO needs to be enabled
2. Check for platform-specific issues
3. Compare with nixpkgs build configuration
4. Review upstream release notes for breaking changes

## Version Support Policy

This repository tracks:
- ✅ **Latest stable release** - Always update to newest version
- ✅ **Previous stable release** - Keep in git history via tags
- ❌ **Multiple concurrent versions** - Not supported (use git tags/branches)

To use an older version:
```bash
# Checkout specific tag
git checkout v1.29.1

# Or use git reference in flake
nix build github:barstoolbluz/build-temporal?ref=v1.29.1
```

## Platform-Specific Notes

### Linux (x86_64, aarch64)
- Standard Go cross-compilation works
- No special considerations

### macOS (Intel, Apple Silicon)
- Go builds are universal
- No special considerations
- CGO disabled, so no native dependencies

### Cross-compilation

Building for different platform:
```bash
# From Linux, build for macOS
nix build .#temporal --system aarch64-darwin

# From macOS, build for Linux
nix build .#temporal --system x86_64-linux
```

Requires:
- Remote builders configured, or
- QEMU for emulation (slow)

## Comparison with nixpkgs Updates

**nixpkgs update process:**
1. Fork nixpkgs repository
2. Find package in `pkgs/by-name/te/temporal/`
3. Update version and hashes
4. Test locally
5. Open pull request
6. Wait for review and merge
7. Wait for channel update

**build-temporal process:**
1. Edit one file (`.flox/pkgs/temporal.nix`)
2. Run `flox build` twice (for hashes)
3. Test and publish
4. Available immediately in your catalog

**Time to update:**
- nixpkgs: Days to weeks
- build-temporal: Minutes

## Release Checklist

When updating to a new version:

- [ ] Check [Temporal releases](https://github.com/temporalio/temporal/releases)
- [ ] Read release notes for breaking changes
- [ ] Update `version` in `temporal.nix`
- [ ] Clear `hash` and `vendorHash`
- [ ] Run `flox build` to get source hash
- [ ] Update `hash` with correct value
- [ ] Run `flox build` to get vendor hash
- [ ] Update `vendorHash` with correct value
- [ ] Run `flox build` - should succeed
- [ ] Test: `./result/bin/temporal-server --version`
- [ ] Test: `./result/bin/temporal-sql-tool --version`
- [ ] Update README.md version badge if present
- [ ] Commit changes: `git commit -m "Update to vX.Y.Z"`
- [ ] Tag release: `git tag vX.Y.Z`
- [ ] Push: `git push && git push --tags`
- [ ] Update flake.lock: `nix flake update`
- [ ] Publish: `flox publish`
- [ ] Verify: `flox search temporal` shows new version

## Examples

### Example Update Session

```bash
# 1. Check current version
cat .flox/pkgs/temporal.nix | grep 'version ='
# version = "1.29.1";

# 2. Check latest release
curl -s https://api.github.com/repos/temporalio/temporal/releases/latest | jq -r '.tag_name'
# v1.30.0

# 3. Edit the file
vim .flox/pkgs/temporal.nix
# Update version to 1.30.0
# Set hash = "" and vendorHash = ""

# 4. Get source hash
flox build 2>&1 | grep "got:"
# got: sha256-ABC123...

# 5. Update hash in file
vim .flox/pkgs/temporal.nix

# 6. Get vendor hash
flox build 2>&1 | grep "got:"
# got: sha256-XYZ789...

# 7. Update vendorHash in file
vim .flox/pkgs/temporal.nix

# 8. Final build
flox build
# Should succeed

# 9. Test
./result/bin/temporal-server --version
# temporal version 1.30.0

# 10. Publish
git add .flox/pkgs/temporal.nix
git commit -m "Update Temporal to v1.30.0"
git push
flox publish
```

## Getting Help

If you encounter issues:

1. Check Temporal's build documentation: https://github.com/temporalio/temporal/blob/main/CONTRIBUTING.md
2. Compare with nixpkgs implementation
3. Check Temporal community forums
4. Open an issue in this repository

## Future Automation

Potential improvements:

**GitHub Actions workflow:**
```yaml
# .github/workflows/check-version.yml
name: Check for new Temporal releases
on:
  schedule:
    - cron: '0 0 * * *'  # Daily
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - name: Check latest release
      - name: Compare with current version
      - name: Open PR if new version available
```

**Automated hash updates:**
- Use `nix-prefetch-github` for source hash
- Parse build output for vendor hash
- Commit and open PR automatically

**Multi-platform CI builds:**
- Build on Linux x86_64
- Build on Linux aarch64
- Build on macOS Intel
- Build on macOS Apple Silicon
- Verify all binaries work

These are left as future enhancements.
