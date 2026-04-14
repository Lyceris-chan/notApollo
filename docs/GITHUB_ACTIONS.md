# GitHub Actions Workflow Guide

This document explains the automated build and release process for notApollo using GitHub Actions.

## Overview

The notApollo project uses GitHub Actions to automatically:
- Build OpenWrt packages for multiple versions and architectures
- Download and bundle all external assets locally
- Create installation and uninstallation scripts
- Publish releases with pre-built packages
- Test package builds and installation scripts

## Workflow Triggers

The build workflow runs on:
- **Push to main/develop**: Builds packages for testing
- **Pull requests**: Validates changes work across all platforms
- **Tagged releases** (`v*`): Creates official releases with all artifacts
- **Manual dispatch**: Can be triggered manually from GitHub UI

## Supported Platforms

### OpenWrt Versions
- **23.05.4**: Current stable release
- **24.10.0**: Latest release

### Architectures
- **ramips/mt76x8**: ASUS RT-AX53U and similar MT7621-based routers
- **x86/64**: x86_64 systems and virtual machines

## Build Process

### 1. Environment Setup
- Ubuntu latest runner
- OpenWrt SDK download and caching
- Build dependencies installation

### 2. Asset Bundling
- Downloads Google Sans Flex fonts from Google Fonts API
- Downloads Chart.js library from CDN
- Downloads Material Symbols icon fonts
- Verifies asset integrity and generates inventory

### 3. Package Building
- Copies source code to OpenWrt SDK
- Updates package feeds
- Compiles notApollo package for each platform
- Generates package metadata and checksums

### 4. Artifact Creation
- Creates installation scripts with auto-detection
- Creates uninstallation scripts
- Packages all artifacts for download

### 5. Release Publishing (Tags Only)
- Creates GitHub release with all packages
- Includes installation instructions
- Provides checksums for verification

## Using Pre-built Packages

### Automatic Installation
```bash
wget -O - https://raw.githubusercontent.com/YOUR_USERNAME/notapollo/main/install-notapollo.sh | sh
```

### Manual Installation
1. Go to [Releases](https://github.com/YOUR_USERNAME/notapollo/releases)
2. Download the appropriate `.ipk` file for your platform
3. Install: `opkg install notapollo_*.ipk`

### Package Naming Convention
```
notapollo_<version>-<openwrt_version>-<architecture>.ipk
```

Examples:
- `notapollo_1.0.0-23.05.4-ramips-mt76x8.ipk`
- `notapollo_1.0.0-24.10.0-x86-64.ipk`

## Development Workflow

### Testing Changes
1. Create a pull request
2. GitHub Actions automatically builds packages for all platforms
3. Download artifacts from the PR checks to test locally

### Creating Releases
1. Update version in relevant files
2. Create and push a git tag: `git tag v1.0.0 && git push origin v1.0.0`
3. GitHub Actions automatically creates a release with all packages

### Local Development
Use the quick start script for local development:
```bash
./scripts/quick-start.sh
```

## Workflow Configuration

### Secrets Required
- `GITHUB_TOKEN`: Automatically provided by GitHub for releases

### Environment Variables
- `PACKAGE_NAME`: Set to "notapollo"
- Matrix builds for multiple OpenWrt versions and architectures

### Caching
- OpenWrt SDKs are cached to speed up builds
- Cache keys include OpenWrt version and target architecture

## Troubleshooting

### Build Failures

**Asset Download Issues:**
- Check internet connectivity in GitHub Actions
- Verify asset URLs are still valid
- Check for rate limiting from external services

**Package Build Issues:**
- Check OpenWrt SDK compatibility
- Verify package dependencies are available
- Check for syntax errors in Makefile

**Release Creation Issues:**
- Ensure tag follows semantic versioning (`v1.0.0`)
- Check that all required artifacts are present
- Verify GitHub token permissions

### Local Testing

Test the workflow locally using act:
```bash
# Install act (GitHub Actions local runner)
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# Run the workflow locally
act push
```

## Monitoring

### Build Status
- Check the Actions tab in GitHub repository
- Build status badges can be added to README.md
- Email notifications for failed builds (configure in GitHub settings)

### Release Metrics
- Download counts for each release
- Platform popularity statistics
- User feedback through GitHub issues

## Security Considerations

### Asset Integrity
- All downloaded assets are verified with checksums
- Asset inventory is generated for transparency
- Build process is reproducible and auditable

### Package Security
- Packages are built in isolated environments
- No secrets or sensitive data in packages
- All source code is publicly auditable

### Distribution Security
- Packages are signed by GitHub's infrastructure
- Checksums provided for manual verification
- Installation scripts validate package integrity

## Contributing to Workflow

### Modifying the Workflow
1. Edit `.github/workflows/build-and-release.yml`
2. Test changes in a fork first
3. Submit pull request with workflow changes

### Adding New Platforms
1. Add new matrix entries for OpenWrt version/architecture
2. Update documentation
3. Test builds on new platforms

### Improving Build Performance
- Optimize caching strategies
- Parallelize independent build steps
- Reduce artifact sizes where possible

## Future Enhancements

### Planned Improvements
- Automated testing on real hardware
- Performance benchmarking
- Security scanning integration
- Multi-architecture container builds

### Community Contributions
- Additional OpenWrt version support
- New architecture targets
- Build optimization suggestions
- Documentation improvements

For questions about the GitHub Actions workflow, please:
1. Check existing GitHub Issues
2. Review workflow logs for error details
3. Create a new issue with workflow-specific label
4. Discuss in GitHub Discussions for general questions