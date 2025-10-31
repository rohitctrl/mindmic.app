#!/bin/bash

# MindMic DMG Creation and Signing Script
# This script creates a professional DMG for distribution with proper signing

set -e  # Exit on any error

# Configuration
APP_NAME="MindMic"
VERSION="2.0"
BUILD_DIR="build"
DMG_NAME="$APP_NAME-$VERSION"
SOURCE_APP="$BUILD_DIR/$APP_NAME.app"
DMG_PATH="$BUILD_DIR/$DMG_NAME.dmg"
TEMP_DMG_DIR="$BUILD_DIR/dmg_temp"

# DMG Appearance
DMG_WINDOW_WIDTH="600"
DMG_WINDOW_HEIGHT="400"
DMG_ICON_SIZE="120"
DMG_TEXT_SIZE="16"
DMG_BACKGROUND_COLOR="#ffffff"
DMG_LICENSE_FILE="LICENSE"  # Optional

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

# Check dependencies
check_dependencies() {
    log_info "Checking dependencies..."

    # Check for required tools
    for tool in hdiutil codesign mktemp sips; do
        if ! command -v $tool &> /dev/null; then
            log_error "$tool not found. Please install Xcode command line tools."
            exit 1
        fi
    done

    log_info "All dependencies found."
}

# Check if app exists
check_app() {
    log_info "Checking for application..."

    if [ ! -d "$SOURCE_APP" ]; then
        log_error "Application not found: $SOURCE_APP"
        log_error "Please build the application first using ./build-distribution.sh"
        exit 1
    fi

    log_info "Application found: $SOURCE_APP"
}

# Verify app signing
verify_app_signing() {
    log_info "Verifying application signing..."

    if codesign -dv "$SOURCE_APP" &> /dev/null; then
        log_info "✅ Application is properly signed"
    else
        log_warn "⚠️  Application may not be signed properly"
        log_info "Attempting to sign application..."

        # Try to sign the app
        if codesign --force --verify --verbose --sign "Developer ID Application" "$SOURCE_APP"; then
            log_info "✅ Application signed successfully"
        else
            log_error "❌ Failed to sign application"
            exit 1
        fi
    fi
}

# Clean previous DMG
clean_previous_dmg() {
    log_info "Cleaning previous DMG files..."

    # Remove existing DMG
    if [ -f "$DMG_PATH" ]; then
        rm -f "$DMG_PATH"
        log_info "Removed existing DMG: $DMG_PATH"
    fi

    # Remove temporary directory
    if [ -d "$TEMP_DMG_DIR" ]; then
        rm -rf "$TEMP_DMG_DIR"
        log_info "Removed temporary directory: $TEMP_DMG_DIR"
    fi

    mkdir -p "$TEMP_DMG_DIR"
}

# Create DMG folder structure
create_dmg_structure() {
    log_step "Creating DMG folder structure..."

    # Copy application
    cp -R "$SOURCE_APP" "$TEMP_DMG_DIR/"
    log_info "Copied application to DMG folder"

    # Create Applications symlink
    ln -s /Applications "$TEMP_DMG_DIR/Applications"
    log_info "Created Applications symlink"

    # Create license file if it doesn't exist
    if [ ! -f "$DMG_LICENSE_FILE" ] && [ ! -f "LICENSE" ]; then
        cat > "$TEMP_DMG_DIR/LICENSE.txt" << EOF
MindMic Software License Agreement

Copyright (c) 2024 Rohit Kumar

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF
        log_info "Created license file"
    elif [ -f "LICENSE" ]; then
        cp "LICENSE" "$TEMP_DMG_DIR/LICENSE.txt"
        log_info "Copied existing license file"
    fi

    # Copy DMG installation README
    if [ -f "DMG_INSTALLATION.md" ]; then
        cp "DMG_INSTALLATION.md" "$TEMP_DMG_DIR/README.txt"
        log_info "Copied DMG installation README"
    else
        # Create a basic installation guide if the file doesn't exist
        cat > "$TEMP_DMG_DIR/README.txt" << EOF
MindMic - Quick Installation Guide

1. Drag MindMic.app to the Applications folder
2. Open MindMic from Applications or Launchpad
3. Grant microphone permission when prompted
4. Configure your preferred settings
5. Start recording by pressing ⌃⌥Space (default hotkey)

For detailed help, visit: https://github.com/rohitctrl/mindmic.app
EOF
        log_info "Created basic installation guide"
    fi

    # Set folder permissions
    chmod -R 755 "$TEMP_DMG_DIR"
    log_info "Set folder permissions"
}

# Create temporary DMG
create_temp_dmg() {
    log_step "Creating temporary DMG..."

    TEMP_DMG="$BUILD_DIR/temp_$DMG_NAME.dmg"

    hdiutil create \
        -srcfolder "$TEMP_DMG_DIR" \
        -volname "$APP_NAME" \
        -fs HFS+ \
        -fsargs "-c c=64,a=16,e=16" \
        -format UDRW \
        "$TEMP_DMG"

    log_info "Temporary DMG created: $TEMP_DMG"
    echo "$TEMP_DMG"
}

# Mount DMG for customization
mount_dmg() {
    local temp_dmg=$1
    log_step "Mounting DMG for customization..."

    # Mount the DMG
    MOUNT_DIR=$(hdiutil attach "$temp_dmg" | grep "/Volumes" | awk '{print $3}')

    if [ -z "$MOUNT_DIR" ]; then
        log_error "Failed to mount DMG"
        exit 1
    fi

    log_info "DMG mounted at: $MOUNT_DIR"
    echo "$MOUNT_DIR"
}

# Customize DMG appearance
customize_dmg() {
    local mount_dir=$1
    log_step "Customizing DMG appearance..."

    # Wait for Finder to register the mount
    sleep 2

    # Use AppleScript to customize window appearance
    osascript << EOF
tell application "Finder"
    tell disk "$APP_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set path bar visible of container window to false
        set sidebar width of container window to 0

        -- Set window size and position
        set bounds of container window to {400, 100, 1000, 500}

        -- Set icon positions
        set the position of item "$APP_NAME.app" to {150, 300}
        set the position of item "Applications" to {450, 300}
        set the position of item "README.txt" to {150, 180}

        -- Set icon sizes
        set icon size of view options of container window to $DMG_ICON_SIZE

        -- Set background color (if desired)
        -- set background picture of view options of container window to file ".background:background.png"

        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOF

    log_info "DMG appearance customized"
}

# Create final DMG
create_final_dmg() {
    local temp_dmg=$1
    log_step "Creating final compressed DMG..."

    # Unmount temporary DMG
    hdiutil detach "/Volumes/$APP_NAME" -force || true
    sleep 2

    # Convert to compressed read-only DMG
    hdiutil convert "$temp_dmg" \
        -format UDBZ \
        -o "$DMG_PATH"

    # Remove temporary DMG
    rm -f "$temp_dmg"

    log_info "Final DMG created: $DMG_PATH"
}

# Sign DMG
sign_dmg() {
    log_step "Signing DMG..."

    # Sign the DMG
    if codesign --force --verify --verbose --sign "Developer ID Application" "$DMG_PATH"; then
        log_info "✅ DMG signed successfully"

        # Verify signature
        if codesign -dv "$DMG_PATH" &> /dev/null; then
            log_info "✅ DMG signature verified"
        else
            log_warn "⚠️  DMG signature verification failed"
        fi
    else
        log_warn "⚠️  Failed to sign DMG (non-critical for distribution)"
    fi
}

# Display DMG information
display_info() {
    log_info "🎉 DMG creation completed successfully!"
    echo
    log_info "DMG Information:"

    if [ -f "$DMG_PATH" ]; then
        DMG_SIZE=$(stat -f%z "$DMG_PATH")
        DMG_SIZE_HUMAN=$(du -h "$DMG_PATH" | cut -f1)

        log_info "  - File: $DMG_PATH"
        log_info "  - Size: $DMG_SIZE bytes ($DMG_SIZE_HUMAN)"
        log_info "  - Version: $VERSION"
        log_info "  - Application: $APP_NAME.app"

        echo
        log_info "DMG Contents:"
        log_info "  - $APP_NAME.app (application)"
        log_info "  - Applications (shortcut to /Applications)"
        log_info "  - README.txt (installation guide)"
        log_info "  - LICENSE.txt (license information)"
    fi

    echo
    log_info "Next Steps:"
    log_info "1. Test the DMG: open $DMG_PATH"
    log_info "2. Notarize the DMG: ./notarize-dmg.sh"
    log_info "3. Upload to GitHub releases"
    log_info "4. Generate appcast.xml: ./generate-appcast.sh"
}

# Cleanup temporary files
cleanup() {
    log_info "Cleaning up temporary files..."

    # Unmount any mounted DMG
    if [ -d "/Volumes/$APP_NAME" ]; then
        hdiutil detach "/Volumes/$APP_NAME" -force || true
    fi

    # Remove temporary directory
    if [ -d "$TEMP_DMG_DIR" ]; then
        rm -rf "$TEMP_DMG_DIR"
    fi

    log_info "Cleanup completed"
}

# Main execution
main() {
    log_info "Starting MindMic DMG creation..."
    log_info "Application: $APP_NAME"
    log_info "Version: $VERSION"
    log_info "Output: $DMG_PATH"

    check_dependencies
    check_app
    verify_app_signing
    clean_previous_dmg
    create_dmg_structure

    # Create and customize DMG
    TEMP_DMG=$(create_temp_dmg)
    MOUNT_DIR=$(mount_dmg "$TEMP_DMG")
    customize_dmg "$MOUNT_DIR"
    create_final_dmg "$TEMP_DMG"

    sign_dmg
    display_info
    cleanup
}

# Handle script interruption
trap 'log_error "Script interrupted"; cleanup; exit 1' INT TERM

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version)
            VERSION="$2"
            DMG_NAME="$APP_NAME-$VERSION"
            DMG_PATH="$BUILD_DIR/$DMG_NAME.dmg"
            shift 2
            ;;
        -a|--app)
            APP_NAME="$2"
            SOURCE_APP="$BUILD_DIR/$APP_NAME.app"
            DMG_NAME="$APP_NAME-$VERSION"
            DMG_PATH="$BUILD_DIR/$DMG_NAME.dmg"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -v, --version VERSION    Set version (default: 2.0)"
            echo "  -a, --app APP_NAME       Set app name (default: MindMic)"
            echo "  -h, --help               Show this help message"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Run main function
main "$@"