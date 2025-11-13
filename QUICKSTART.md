# build-temporal Quick Start

Get from `/tmp/build-temporal/` to published FloxHub package in 5 minutes.

## Prerequisites

- ✅ Flox installed
- ✅ Git installed
- ✅ GitHub account
- ✅ Logged in to FloxHub (`flox auth login`)

## Step 1: Copy to Your Projects Directory (30 seconds)

```bash
# Copy the repository
cp -r /tmp/build-temporal ~/dev/build-temporal
cd ~/dev/build-temporal

# Initialize git
git init
git add .
git commit -m "Initial commit: Temporal v1.29.1"
```

## Step 2: Create GitHub Repository (1 minute)

**On GitHub:**
1. Go to https://github.com/new
2. Repository name: `build-temporal`
3. Description: `Nix/Flox build for Temporal orchestration platform`
4. Make it public (for FloxHub)
5. Click "Create repository"

**In terminal:**
```bash
git remote add origin git@github.com:YOUR_USERNAME/build-temporal.git
git branch -M main
git push -u origin main
```

## Step 3: Test Build (2 minutes)

```bash
# Activate build environment
flox activate

# Build the package
flox build

# Test binaries
./result/bin/temporal-server --version
# Should show: temporal version 1.29.1

./result/bin/temporal-sql-tool --version
./result/bin/temporal-cassandra-tool --version
./result/bin/tdbg --version
```

If all commands work: ✅ Build successful!

## Step 4: Publish to FloxHub (30 seconds)

```bash
flox publish
```

You'll see:
```
✅ Published temporal@1.29.1 to your catalog
```

## Step 5: Verify Publication (30 seconds)

```bash
# Search your catalog
flox search temporal

# Show package details
flox show temporal
```

## Step 6: Use in temporal-headless (1 minute)

```bash
cd /path/to/temporal-headless

# Edit manifest
flox edit
```

Change:
```toml
[install]
temporal.pkg-path = "temporal"  # Now uses YOUR build!
```

Test:
```bash
flox activate -s
# temporal-server should start with your custom build
```

## Done! 🎉

You now have:
- ✅ build-temporal repository on GitHub
- ✅ Custom Temporal package in FloxHub
- ✅ Version tracking for future updates
- ✅ Fast update workflow (5-10 minutes per release)

## Next Steps

### When Temporal 1.30.0 is Released

```bash
cd ~/dev/build-temporal

# Edit version
vim .flox/pkgs/temporal.nix
# Change version = "1.29.1" to "1.30.0"
# Set hash = "" and vendorHash = ""

# Get source hash
flox build 2>&1 | grep "got:"
# Copy the hash

# Update hash in temporal.nix
vim .flox/pkgs/temporal.nix

# Get vendor hash
flox build 2>&1 | grep "got:"
# Copy the hash

# Update vendorHash in temporal.nix
vim .flox/pkgs/temporal.nix

# Final build
flox build

# Test
./result/bin/temporal-server --version

# Commit
git add .
git commit -m "Update to v1.30.0"
git tag v1.30.0
git push --tags

# Publish
flox publish
```

**Time:** 5-10 minutes

### Use Specific Version

```toml
# In any flox environment
[install]
temporal.pkg-path = "github:YOUR_USERNAME/build-temporal?ref=v1.29.1#temporal"
```

### Share with Others

Send them:
```bash
flox install github:YOUR_USERNAME/build-temporal#temporal
```

## Troubleshooting

### Build fails with hash error

**Expected!** This is how you get the correct hash. Copy the `got:` value and update `temporal.nix`.

### Build fails with Go errors

Check:
1. Go version: `go version` (should be 1.21+)
2. Upstream build: https://github.com/temporalio/temporal/actions
3. Platform compatibility

### Publish fails

Check:
```bash
# Are you logged in?
flox auth status

# Is repository public?
# FloxHub requires public GitHub repos
```

### temporal-server crashes

Test with:
```bash
./result/bin/temporal-server --version
./result/bin/temporal-server --help
```

If version works but help crashes, check build flags in `temporal.nix`.

## Tips

### Test Before Publishing

```toml
# Use local path first
[install]
temporal.pkg-path = "path:~/dev/build-temporal#temporal"
```

### Multiple Versions

```bash
# Keep old version in git
git tag v1.29.1

# Users can reference specific tags
temporal.pkg-path = "github:YOU/build-temporal?ref=v1.29.1#temporal"
```

### Automation

Set up GitHub Actions to check for new releases:

```yaml
# .github/workflows/check-updates.yml
name: Check Temporal Updates
on:
  schedule:
    - cron: '0 0 * * *'  # Daily
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - name: Check latest release
        run: |
          LATEST=$(curl -s https://api.github.com/repos/temporalio/temporal/releases/latest | jq -r .tag_name)
          echo "Latest: $LATEST"
```

## Common Workflows

### Development

```bash
cd ~/dev/build-temporal
flox activate

# Edit build
vim .flox/pkgs/temporal.nix

# Test
flox build

# Iterate
```

### Production Update

```bash
# Update version
vim .flox/pkgs/temporal.nix

# Build
flox build

# Test locally
./result/bin/temporal-server --version

# Test in real environment
cd /path/to/temporal-headless
flox edit  # Update to github:YOU/build-temporal
flox activate -s

# If working, publish
cd ~/dev/build-temporal
git add .
git commit -m "Update to vX.Y.Z"
git tag vX.Y.Z
git push --tags
flox publish
```

### Rollback

```bash
# In temporal-headless
flox edit

# Pin to old version
[install]
temporal.pkg-path = "github:YOU/build-temporal?ref=v1.29.1#temporal"
```

## Resources

- **Full docs**: See README.md
- **Update guide**: See BUILD_VERSIONS.md
- **Flox usage**: See FLOX.md
- **Pattern comparison**: See `/tmp/build-temporal-vs-build-dagster-comparison.md`

## Success Checklist

After completing this quickstart, you should have:

- [x] Repository in `~/dev/build-temporal`
- [x] Git initialized and committed
- [x] GitHub repository created
- [x] Local build working (`flox build`)
- [x] All binaries tested (version commands work)
- [x] Published to FloxHub (`flox publish`)
- [x] Searchable in catalog (`flox search temporal`)
- [x] Working in temporal-headless

If all checked: **You're ready! 🚀**

## What's Next?

1. **Use it**: Switch temporal-headless to your build
2. **Update it**: When Temporal releases new version
3. **Share it**: Tell others about your catalog
4. **Automate it**: Add GitHub Actions
5. **Extend it**: Create build-temporal-cli for the CLI

Happy building! 🎉
