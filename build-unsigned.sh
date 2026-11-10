#!/bin/bash

# MindMic Unsigned Build Script
# Build and ad-hoc sign the app for free distribution.

set -e  # Exit on any error

# Configuration
PROJECT_NAME="mindmic"
SCHEME="mindmic"
WORKSPACE="mindmic.xcodeproj"
CONFIGURATION="Release"
BUILD_DIR="build-unsigned"
ARCHIVE_PATH="$BUILD_DIR/$PROJECT_NAME.xcarchive"
APP_NAME="MindMic.app"
DMG_NAME="MindMic"
VERSION="${VERSION:-2.0.5}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check if required tools are available
check_dependencies() {
    log_info "Checking dependencies..."

    if ! command -v xcodebuild &> /dev/null; then
        log_error "xcodebuild not found. Please install Xcode command line tools."
        exit 1
    fi

    if ! command -v hdiutil &> /dev/null; then
        log_error "hdiutil not found. Please ensure Xcode is properly installed."
        exit 1
    fi

    log_info "All dependencies found."
}

# Clean previous builds
clean_build() {
    log_info "Cleaning previous unsigned builds..."
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"
}

# Build the archive without signing
build_archive() {
    log_step "Building unsigned archive..."

    xcodebuild archive \
        -project "$WORKSPACE" \
        -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        -archivePath "$ARCHIVE_PATH" \
        -destination "generic/platform=macOS" \
        ONLY_ACTIVE_ARCH=NO \
        ARCHS=arm64 \
        VALID_ARCHS=arm64 \
        MARKETING_VERSION="$VERSION" \
        CURRENT_PROJECT_VERSION="$(date +%s)" \
        CODE_SIGN_IDENTITY="" \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGNING_ALLOWED=NO \
        -quiet

    if [ $? -eq 0 ]; then
        log_info "✅ Unsigned archive created successfully at $ARCHIVE_PATH"
    else
        log_error "❌ Failed to create archive"
        exit 1
    fi
}

# Extract directly: a development export can reintroduce provisioning profiles.
export_app() {
    log_step "Extracting app from archive..."
    local source_app="$ARCHIVE_PATH/Products/Applications/mindmic.app"
    test -d "$source_app"
    ditto "$source_app" "$BUILD_DIR/$APP_NAME"
}

adhoc_sign() {
    log_step "Preparing free distribution signature..."
    python3 .github/scripts/sign-adhoc.py "$BUILD_DIR/$APP_NAME" mindmic/mindmic.entitlements
    python3 .github/scripts/verify-release.py "$BUILD_DIR/$APP_NAME"
}

# Create DMG
create_dmg() {
    log_step "Creating unsigned DMG..."

    DMG_PATH="$BUILD_DIR/$DMG_NAME-$VERSION-unsigned.dmg"

    # Create temporary DMG folder
    DMG_FOLDER="$BUILD_DIR/dmg_temp"
    mkdir -p "$DMG_FOLDER"

    # Copy app to DMG folder
    ditto "$BUILD_DIR/$APP_NAME" "$DMG_FOLDER/$APP_NAME"

    # Create Applications folder symlink
    ln -s /Applications "$DMG_FOLDER/Applications"

    # Create installation instructions
    cat > "$DMG_FOLDER/INSTALL-README.txt" << EOF
MindMic Installation Instructions

⚠️  IMPORTANT: This is an unsigned application

macOS will show a security warning when you first try to open MindMic.
The expected message says Apple cannot verify the developer. Other alerts need investigation.

HOW TO INSTALL:
1. Drag MindMic.app to your Applications folder
2. Open MindMic once, click Done, then System Settings > Privacy & Security > "Open Anyway"
3. If macOS says "damaged" or "contains malware", stop and report the message.
4. Grant microphone and screen recording permissions when prompted

FOR MORE HELP:
- Visit: https://github.com/rohitctrl/mindmic.app
- Check the INSTALLATION.md file for detailed instructions

Thank you for using MindMic!
EOF

    # Create DMG
    hdiutil create \
        -srcfolder "$DMG_FOLDER" \
        -volname "$DMG_NAME" \
        -fs HFS+ \
        -fsargs "-c c=64,a=16,e=16" \
        -format UDBZ \
        "$DMG_PATH"

    if [ $? -eq 0 ]; then
        log_info "✅ DMG created successfully at $DMG_PATH"
    else
        log_error "❌ Failed to create DMG"
        exit 1
    fi

    # Clean up temporary folder
    rm -rf "$DMG_FOLDER"

    # Get DMG size for distribution
    DMG_SIZE=$(stat -f%z "$DMG_PATH")
    log_info "DMG size: $DMG_SIZE bytes"

    # Save size to file for distribution scripts
    echo "$DMG_SIZE" > "$BUILD_DIR/dmg_size.txt"
}

# Generate SHA256 checksums
generate_checksums() {
    log_step "Generating SHA256 checksums..."

    DMG_PATH="$BUILD_DIR/$DMG_NAME-$VERSION-unsigned.dmg"

    if [ -f "$DMG_PATH" ]; then
        # Generate SHA256 checksum
        SHA256=$(shasum -a 256 "$DMG_PATH" | awk '{print $1}')

        # Save checksum to file
        echo "$SHA256  $(basename "$DMG_PATH")" > "$BUILD_DIR/checksums.txt"

        log_info "✅ SHA256: $SHA256"
        log_info "✅ Checksums saved to $BUILD_DIR/checksums.txt"

        # Display checksum for easy copying
        echo
        log_info "📋 SHA256 Checksum (copy for distribution):"
        echo "$SHA256"
        echo
    else
        log_error "❌ DMG file not found for checksum generation"
        exit 1
    fi
}

# Create ZIP archive as alternative
create_zip() {
    log_step "Creating ZIP archive..."

    ZIP_PATH="$BUILD_DIR/$DMG_NAME-$VERSION-unsigned.zip"
    APP_PATH="$BUILD_DIR/$APP_NAME"

    if [ -d "$APP_PATH" ]; then
        # Create ZIP
        cd "$BUILD_DIR"
        ditto -c -k --keepParent "$APP_NAME" "$(basename "$ZIP_PATH")"
        cd - > /dev/null

        if [ $? -eq 0 ]; then
            log_info "✅ ZIP created successfully at $ZIP_PATH"

            # Generate SHA256 for ZIP
            ZIP_SHA256=$(shasum -a 256 "$ZIP_PATH" | awk '{print $1}')
            echo "$ZIP_SHA256  $(basename "$ZIP_PATH")" >> "$BUILD_DIR/checksums.txt"

            log_info "✅ ZIP SHA256: $ZIP_SHA256"
        else
            log_error "❌ Failed to create ZIP"
        fi
    fi
}

# Display build information
display_info() {
    log_info "🎉 Unsigned build completed successfully!"
    echo
    log_info "Build artifacts:"

    if [ -f "$BUILD_DIR/$DMG_NAME-$VERSION-unsigned.dmg" ]; then
        DMG_SIZE=$(cat "$BUILD_DIR/dmg_size.txt")
        log_info "  📦 DMG: $DMG_NAME-$VERSION-unsigned.dmg ($DMG_SIZE bytes)"
    fi

    if [ -f "$BUILD_DIR/$DMG_NAME-$VERSION-unsigned.zip" ]; then
        log_info "  📦 ZIP: $DMG_NAME-$VERSION-unsigned.zip"
    fi

    log_info "  🔍 Checksums: $BUILD_DIR/checksums.txt"
    log_info "  📱 App: $BUILD_DIR/$APP_NAME"
    echo

    log_info "📋 Distribution Information:"
    log_info "  - Version: $VERSION"
    log_info "  - Build: Ad-hoc signed (not notarized)"
    log_info "  - Architecture: ARM64 (Apple Silicon)"
    log_info "  - Minimum macOS: 14.0"
    echo

    log_info "🚀 Next Steps:"
    log_info "  1. Upload DMG/ZIP to GitHub releases"
    log_info "  2. Include SHA256 checksums in release notes"
    log_info "  3. Update Homebrew formula with new checksum"
    log_info "  4. Test installation on fresh macOS system"
    echo

    log_info "⚠️  User Instructions (include in release):"
    log_info "  - Download DMG or ZIP"
    log_info "  - Open once, then System Settings > Privacy & Security > Open Anyway"
    log_info "  - Grant microphone and screen recording permissions"
    log_info "  - Add to Applications folder"
}

# Main execution
main() {
    log_info "Starting MindMic unsigned build process..."
    log_info "Version: $VERSION"
    log_info "Build Type: Unsigned (free distribution)"
    echo

    check_dependencies
    clean_build
    build_archive
    export_app
    adhoc_sign
    create_dmg
    generate_checksums
    create_zip
    display_info
}

# Handle script interruption
trap 'log_error "Script interrupted"; exit 1' INT TERM

# Run main function
main "$@"