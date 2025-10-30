# MindMic Distribution Guide

This guide provides step-by-step instructions for distributing MindMic using direct distribution with Sparkle updates.

## Prerequisites

### 1. Apple Developer Account
- ✅ Enroll in Apple Developer Program ($99/year)
- ✅ Visit [developer.apple.com](https://developer.apple.com)
- ✅ Complete enrollment process

### 2. Development Environment
- ✅ Xcode 16.0+ installed
- ✅ Command Line Tools installed
- ✅ macOS 14.0+ development machine
- ✅ Git configured for GitHub access

### 3. Required Certificates
After enrolling in Apple Developer Program, you'll need to:

1. **Generate Developer ID Certificate**
   ```bash
   # In Xcode: Preferences > Accounts > Your Apple ID > Manage Certificates
   # Click "+" and select "Developer ID Application"
   ```

2. **Download and Install Certificate**
   - Download the generated certificate (.cer)
   - Install in Keychain Access
   - Ensure it's available in your login keychain

## Distribution Workflow

### Phase 1: Preparation ✅

- [x] Create exportOptions.plist for Developer ID signing
- [x] Set up distribution build scripts
- [x] Configure GitHub Actions for automated releases
- [x] Set up appcast.xml generation
- [x] Update version to 2.0 for distribution release

### Phase 2: Build and Sign

1. **Set Environment Variables**
   ```bash
   export APPLE_ID="your-email@example.com"
   export APPLE_ID_PASSWORD="your-app-specific-password"
   export TEAM_ID="YOUR_TEAM_ID"  # e.g., 353GDY5F9V
   ```

2. **Run Distribution Build**
   ```bash
   ./build-distribution.sh
   ```

   This will:
   - Clean previous builds
   - Build archive for distribution
   - Export app with Developer ID signing
   - Create DMG with proper structure
   - Sign DMG for distribution

3. **Verify Build Output**
   - ✅ `build/MindMic.app` - Signed application
   - ✅ `build/MindMic-2.0.dmg` - Distribution DMG
   - ✅ `build/mindmic.xcarchive` - Xcode archive

### Phase 3: Notarization

1. **Upload for Notarization**
   ```bash
   ./notarize-dmg.sh
   ```

   This script will:
   - Upload DMG to Apple's notarization service
   - Monitor notarization status
   - Download notarization ticket
   - Staple ticket to DMG
   - Verify notarization

2. **Monitor Progress**
   - Script will automatically check status every 30 seconds
   - Typical notarization time: 5-15 minutes
   - Look for ✅ success message

### Phase 4: Release

1. **Create GitHub Release**
   ```bash
   # Option A: Use GitHub Actions (recommended)
   git tag v2.0
   git push origin v2.0

   # Option B: Manual release
   # Upload DMG to GitHub releases manually
   ```

2. **Generate Appcast**
   ```bash
   ./generate-appcast.sh --version 2.0 --build 160
   ```

   This will:
   - Generate edSignature for the DMG
   - Create appcast.xml with release information
   - Validate XML structure

3. **Update Website**
   - Upload `appcast.xml` to your website
   - Ensure URL matches `https://beingpax.github.io/mindmic/appcast.xml`
   - Test the Sparkle update mechanism

## File Structure After Distribution

```
mind-mic/
├── build/
│   ├── MindMic.app/           # Signed and notarized app
│   ├── MindMic-2.0.dmg        # Distribution DMG
│   ├── mindmic.xcarchive/     # Xcode archive
│   └── dmg_size.txt           # DMG size information
├── exportOptions.plist        # Export configuration
├── build-distribution.sh      # Build script
├── notarize-dmg.sh           # Notarization script
├── generate-appcast.sh       # Appcast generation script
├── appcast.xml               # Sparkle update feed
└── .github/workflows/
    └── release.yml           # GitHub Actions workflow
```

## Environment Variables

### Required for Distribution

```bash
# Apple Developer credentials
export APPLE_ID="your-email@example.com"
export APPLE_ID_PASSWORD="app-specific-password"
export TEAM_ID="YOUR_TEAM_ID"

# Build configuration (optional, defaults in scripts)
export VERSION="2.0"
export BUILD_NUMBER="160"
```

### Generating App-Specific Password

1. Visit [appleid.apple.com](https://appleid.apple.com)
2. Sign in with your Apple ID
3. Go to "Security" section
4. Click "Generate Password"
5. Label: "MindMic Distribution"
6. Copy the generated password
7. Use this for `APPLE_ID_PASSWORD`

## Automated Release with GitHub Actions

### Setup

1. **Add GitHub Secrets**
   - `APPLE_ID`: Your Apple Developer email
   - `APPLE_ID_PASSWORD`: App-specific password
   - `TEAM_ID`: Your Apple Developer Team ID

2. **Configure Workflow**
   - File: `.github/workflows/release.yml`
   - Triggers: Tag push (`v*`) or manual dispatch

3. **Release Process**
   ```bash
   # Create and push tag
   git tag v2.0
   git push origin v2.0

   # Or trigger manually via GitHub Actions UI
   ```

### GitHub Actions Features

- ✅ Automated build and archive
- ✅ DMG creation with proper structure
- ✅ GitHub release creation
- ✅ Artifact preservation
- ✅ Appcast information generation

## Testing Distribution

### 1. Local Testing
```bash
# Test build process
./build-distribution.sh

# Verify app runs correctly
open build/MindMic.app

# Test DMG mounting
open build/MindMic-2.0.dmg
```

### 2. Notarization Testing
```bash
# Test notarization process
./notarize-dmg.sh

# Verify notarization
xcrun stapler validate build/MindMic-2.0.dmg
```

### 3. Update Testing
```bash
# Test appcast generation
./generate-appcast.sh

# Validate appcast.xml
xmllint --noout appcast.xml
```

## Troubleshooting

### Common Issues

1. **Code Signing Errors**
   ```
   Error: No matching provisioning profile found
   ```
   **Solution**: Ensure Developer ID certificate is installed and selected in Xcode

2. **Notarization Failures**
   ```
   Error: Invalid package
   ```
   **Solution**: Check app structure and entitlements, ensure all binaries are signed

3. **GitHub Actions Failures**
   ```
   Error: APPLE_ID not set
   ```
   **Solution**: Add required secrets to GitHub repository settings

4. **Sparkle Update Issues**
   ```
   Error: Invalid signature
   ```
   **Solution**: Regenerate edSignature with proper Sparkle tools

### Debug Commands

```bash
# Check code signing
codesign -dv MindMic.app

# Verify notarization
xcrun stapler validate MindMic-2.0.dmg

# Check app structure
spctl -a -v MindMic.app

# Test DMG integrity
hdiutil verify MindMic-2.0.dmg
```

## Security Considerations

### 1. Certificate Security
- 🔒 Store Developer ID certificate securely
- 🔒 Use app-specific passwords (not main Apple ID password)
- 🔒 Rotate passwords periodically

### 2. Build Environment
- 🔒 Use secure build machine
- 🔒 Don't commit sensitive credentials
- 🔒 Validate third-party dependencies

### 3. Distribution Security
- 🔒 Always notarize distributed builds
- 🔒 Use HTTPS for all distribution URLs
- 🔒 Validate appcast.xml integrity

## Release Checklist

### Before Release
- [ ] Apple Developer account active
- [ ] Developer ID certificate installed
- [ ] Version number updated in Xcode
- [ ] Build number incremented
- [ ] Changelog prepared
- [ ] Test builds passing

### During Release
- [ ] Run `./build-distribution.sh`
- [ ] Verify app functionality
- [ ] Run `./notarize-dmg.sh`
- [ ] Monitor notarization status
- [ ] Create GitHub release
- [ ] Upload DMG to release
- [ ] Generate appcast.xml
- [ ] Update website

### After Release
- [ ] Test update mechanism
- [ ] Monitor for issues
- [ ] Update documentation
- [ ] Archive build artifacts
- [ ] Clean temporary files

## Support Resources

- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [Sparkle Documentation](https://sparkle-project.org/documentation/)
- [Xcode Documentation](https://developer.apple.com/xcode/)
- [macOS Notarization Guide](https://developer.apple.com/documentation/xcode/notarizing_macos_software_before_distribution)

## Quick Start Summary

For experienced developers, here's the quick workflow:

```bash
# 1. Set credentials
export APPLE_ID="your-email@example.com"
export APPLE_ID_PASSWORD="app-specific-password"
export TEAM_ID="YOUR_TEAM_ID"

# 2. Build and sign
./build-distribution.sh

# 3. Notarize
./notarize-dmg.sh

# 4. Create release
git tag v2.0 && git push origin v2.0

# 5. Update appcast
./generate-appcast.sh --version 2.0

# 6. Upload appcast.xml to website
# 7. Test Sparkle update mechanism
```

Your MindMic app is now ready for distribution! 🎉