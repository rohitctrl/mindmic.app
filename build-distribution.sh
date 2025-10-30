#!/bin/bash

# MindMic Distribution Build Script
# This script builds the app for distribution with proper signing and notarization

set -e  # Exit on any error

# Configuration
PROJECT_NAME="mindmic"
SCHEME="mindmic"
WORKSPACE="mindmic.xcodeproj"
CONFIGURATION="Release"
EXPORT_OPTIONS_PLIST="exportOptions.plist"
BUILD_DIR="build"
ARCHIVE_PATH="$BUILD_DIR/$PROJECT_NAME.xcarchive"
APP_NAME="MindMic.app"
DMG_NAME="MindMic"
VERSION="2.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Check if required tools are available
check_dependencies() {
    log_info "Checking dependencies..."

    if ! command -v xcodebuild &> /dev/null; then
        log_error "xcodebuild not found. Please install Xcode command line tools."
        exit 1
    fi

    if ! command -v xcrun &> /dev/null; then
        log_error "xcrun not found. Please install Xcode command line tools."
        exit 1
    fi

    if ! command -v codesign &> /dev/null; then
        log_error "codesign not found. Please install Xcode command line tools."
        exit 1
    fi

    log_info "All dependencies found."
}

# Clean previous builds
clean_build() {
    log_info "Cleaning previous builds..."
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"
}

# Build the archive
build_archive() {
    log_info "Building archive for distribution..."

    xcodebuild archive \
        -project "$WORKSPACE" \
        -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        -archivePath "$ARCHIVE_PATH" \
        -destination "generic/platform=macOS" \
        ONLY_ACTIVE_ARCH=NO \
        VALID_ARCHS="arm64" \
        -quiet

    if [ $? -eq 0 ]; then
        log_info "Archive created successfully at $ARCHIVE_PATH"
    else
        log_error "Failed to create archive"
        exit 1
    fi
}

# Export the app
export_app() {
    log_info "Exporting app for distribution..."

    xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportPath "$BUILD_DIR" \
        -exportOptionsPlist "$EXPORT_OPTIONS_PLIST" \
        -quiet

    if [ $? -eq 0 ]; then
        log_info "App exported successfully"
    else
        log_error "Failed to export app"
        exit 1
    fi

    # Verify the app exists
    if [ ! -d "$BUILD_DIR/$APP_NAME" ]; then
        log_error "Exported app not found at $BUILD_DIR/$APP_NAME"
        exit 1
    fi
}

# Verify code signing
verify_signing() {
    log_info "Verifying code signing..."

    codesign -dv "$BUILD_DIR/$APP_NAME"

    if [ $? -eq 0 ]; then
        log_info "Code signing verified successfully"
    else
        log_error "Code signing verification failed"
        exit 1
    fi
}

# Create DMG
create_dmg() {
    log_info "Creating DMG..."

    DMG_PATH="$BUILD_DIR/$DMG_NAME-$VERSION.dmg"

    # Create temporary DMG folder
    DMG_FOLDER="$BUILD_DIR/dmg_temp"
    mkdir -p "$DMG_FOLDER"

    # Copy app to DMG folder
    cp -R "$BUILD_DIR/$APP_NAME" "$DMG_FOLDER/"

    # Create Applications folder symlink
    ln -s /Applications "$DMG_FOLDER/Applications"

    # Create DMG
    hdiutil create \
        -srcfolder "$DMG_FOLDER" \
        -volname "$DMG_NAME" \
        -fs HFS+ \
        -fsargs "-c c=64,a=16,e=16" \
        -format UDBZ \
        "$DMG_PATH"

    if [ $? -eq 0 ]; then
        log_info "DMG created successfully at $DMG_PATH"
    else
        log_error "Failed to create DMG"
        exit 1
    fi

    # Clean up temporary folder
    rm -rf "$DMG_FOLDER"

    # Get DMG size for appcast
    DMG_SIZE=$(stat -f%z "$DMG_PATH")
    log_info "DMG size: $DMG_SIZE bytes"

    # Save size to file for appcast generation
    echo "$DMG_SIZE" > "$BUILD_DIR/dmg_size.txt"
}

# Sign DMG (optional but recommended)
sign_dmg() {
    log_info "Signing DMG..."

    DMG_PATH="$BUILD_DIR/$DMG_NAME-$VERSION.dmg"

    # Sign the DMG
    codesign --force --verify --verbose --sign "Developer ID Application" "$DMG_PATH"

    if [ $? -eq 0 ]; then
        log_info "DMG signed successfully"
    else
        log_warn "DMG signing failed (non-critical)"
    fi
}

# Main execution
main() {
    log_info "Starting MindMic distribution build process..."
    log_info "Version: $VERSION"

    check_dependencies
    clean_build
    build_archive
    export_app
    verify_signing
    create_dmg
    sign_dmg

    log_info "Distribution build completed successfully!"
    log_info "Output files:"
    log_info "  - App: $BUILD_DIR/$APP_NAME"
    log_info "  - DMG: $BUILD_DIR/$DMG_NAME-$VERSION.dmg"
    log_info "  - Archive: $ARCHIVE_PATH"

    log_info "Next steps:"
    log_info "1. Notarize the DMG: ./notarize-dmg.sh"
    log_info "2. Staple the DMG: ./staple-dmg.sh"
    log_info "3. Upload to GitHub releases"
    log_info "4. Update appcast.xml"
}

# Run main function
main "$@"