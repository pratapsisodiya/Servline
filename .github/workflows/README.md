# GitHub Actions Workflows

## Build and Release APK

Automatically builds and releases APK when code is pushed to the `main` branch.

### What it does:
1. ✅ Builds release APK (ARM64, ARMv7, x86_64)
2. ✅ Builds App Bundle (.aab) for Play Store
3. ✅ Creates GitHub Release with version tag
4. ✅ Uploads all build artifacts

### How to use:
- Push to `main` branch → Automatic build and release
- Manual trigger: Go to Actions tab → Select workflow → Run workflow

### Requirements:
- Repository must have GitHub Actions enabled
- No additional secrets needed (uses GITHUB_TOKEN)

### Output:
- Release APKs in GitHub Releases
- Build artifacts stored for 30 days
- Version automatically extracted from pubspec.yaml
