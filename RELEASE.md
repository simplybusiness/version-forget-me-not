# Release Process

This document describes the release process for Version Forget-Me-Not GitHub Action.

## Publishing a New Release

### 1. Update Version References

Before creating a release, ensure any version references in documentation are up to date.

### 2. Create a GitHub Release

1. Go to the [Releases page](https://github.com/simplybusiness/version-forget-me-not/releases)
2. Click "Draft a new release"
3. Create a new tag following semantic versioning (e.g., `v2.1.0`)
4. Add release notes describing the changes
5. Publish the release

### 3. Automated Publishing

When you publish a release, the following happens automatically:

1. **Docker Image Publishing**: The `publish.yml` workflow builds and pushes the Docker image to GitHub Container Registry (GHCR) with multiple tags:
   - Exact version: `ghcr.io/simplybusiness/version-forget-me-not:v2.1.0`
   - Minor version: `ghcr.io/simplybusiness/version-forget-me-not:v2.1`
   - Major version: `ghcr.io/simplybusiness/version-forget-me-not:v2`
   - Latest: `ghcr.io/simplybusiness/version-forget-me-not:latest`

2. **Major Version Tag Update**: The major version tag (e.g., `v2`) is automatically updated to point to the latest release in that major version series.

This ensures users referencing `@v2` in their workflows automatically get the latest v2.x.x release.

## Using Pre-built Docker Images

Users can optionally use pre-built Docker images for faster execution:

### Standard Usage (Dockerfile)
```yaml
- uses: simplybusiness/version-forget-me-not@v2
  env:
    ACCESS_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    VERSION_FILE_PATH: "lib/my_gem/version.rb"
```

### Pre-built Image Usage (Faster)
```yaml
- uses: docker://ghcr.io/simplybusiness/version-forget-me-not:v2
  env:
    ACCESS_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    VERSION_FILE_PATH: "lib/my_gem/version.rb"
```

The pre-built image approach:
- Skips Docker build time (faster execution)
- Uses cached image from GHCR
- Recommended for workflows running frequently

## Manual Publishing

If needed, you can manually trigger the publish workflow:

1. Go to Actions → Publish Docker Image
2. Click "Run workflow"
3. Enter the tag to publish (e.g., `v2.1.0`)
4. Click "Run workflow"

## Version Support

- **Major versions** (e.g., v2): Automatically updated to latest minor/patch
- **Minor versions** (e.g., v2.1): Automatically updated to latest patch
- **Exact versions** (e.g., v2.1.0): Fixed, never changes

Users should typically reference major versions (`@v2`) to get automatic updates while maintaining compatibility.
