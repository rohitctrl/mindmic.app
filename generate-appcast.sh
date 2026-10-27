#!/bin/bash

# MindMic Appcast Generation Script
# This script generates the appcast.xml file for Sparkle updates

set -e  # Exit on any error

# Configuration
VERSION="2.0"
BUILD="160"
DMG_NAME="MindMic"
BUILD_DIR="build"
APPCAST_FILE="appcast.xml"
DOWNLOAD_BASE_URL="https://github.com/rohitctrl/mindmic.app/releases/download"
WEBSITE_URL="https://beingpax.github.io/mindmic"

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

# Check for dependencies
check_dependencies() {
    log_info "Checking dependencies..."

    # Check for sparkle command line tools
    if ! command -v sign_update &> /dev/null; then
        log_warn "Sparkle sign_update command not found"
        log_info "Make sure Sparkle tools are installed"
        log_info "They should be available at: /usr/local/bin/sign_update"
    fi

    # Check for openssl
    if ! command -v openssl &> /dev/null; then
        log_error "openssl not found. Please install OpenSSL."
        exit 1
    fi

    log_info "Dependencies checked."
}

# Get DMG information
get_dmg_info() {
    log_step "Getting DMG information..."

    DMG_PATH="$BUILD_DIR/$DMG_NAME-$VERSION.dmg"

    if [ ! -f "$DMG_PATH" ]; then
        log_error "DMG file not found: $DMG_PATH"
        log_error "Please run ./build-distribution.sh first"
        exit 1
    fi

    # Get DMG size
    DMG_SIZE=$(stat -f%z "$DMG_PATH")
    log_info "DMG size: $DMG_SIZE bytes"

    # Get current date
    RELEASE_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    log_info "Release date: $RELEASE_DATE"
}

# Generate edSignature for the DMG
generate_signature() {
    log_step "Generating edSignature..."

    DMG_PATH="$BUILD_DIR/$DMG_NAME-$VERSION.dmg"
    SIGNATURE_FILE="$BUILD_DIR/$DMG_NAME-$VERSION.sig"

    if command -v sign_update &> /dev/null; then
        # Use Sparkle's sign_update tool
        sign_update "$DMG_PATH" "$SIGNATURE_FILE"

        if [ -f "$SIGNATURE_FILE" ]; then
            # Read the signature
            SIGNATURE=$(cat "$SIGNATURE_FILE")
            log_info "Signature generated successfully"
            rm "$SIGNATURE_FILE"  # Clean up
        else
            log_warn "Failed to generate signature with Sparkle tool"
            SIGNATURE="PLACEHOLDER_SIGNATURE"
        fi
    else
        log_warn "Sparkle sign_update tool not available"
        log_info "Using placeholder signature - please update manually"
        SIGNATURE="PLACEHOLDER_SIGNATURE"
    fi

    log_info "Signature: ${SIGNATURE:0:50}..."
}

# Backup existing appcast
backup_appcast() {
    if [ -f "$APPCAST_FILE" ]; then
        log_info "Backing up existing appcast.xml"
        cp "$APPCAST_FILE" "$APPCAST_FILE.backup"
    fi
}

# Generate new appcast.xml
generate_appcast() {
    log_step "Generating appcast.xml..."

    DOWNLOAD_URL="$DOWNLOAD_BASE_URL/v$VERSION/$DMG_NAME-$VERSION.dmg"
    RELEASE_NOTES_URL="$DOWNLOAD_BASE_URL/v$VERSION"

    cat > "$APPCAST_FILE" << EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
  <channel>
    <title>MindMic Release Notes</title>
    <link>$WEBSITE_URL/</link>
    <description>Most recent changes with links to updates.</description>
    <language>en</language>
    <item>
      <title>Version $VERSION</title>
      <link>$WEBSITE_URL/</link>
      <sparkle:releaseNotesLink>
        $RELEASE_NOTES_URL
      </sparkle:releaseNotesLink>
      <pubDate>$RELEASE_DATE</pubDate>
      <enclosure
        url="$DOWNLOAD_URL"
        sparkle:version="$BUILD"
        sparkle:shortVersionString="$VERSION"
        length="$DMG_SIZE"
        type="application/octet-stream"
        sparkle:edSignature="$SIGNATURE"
      />
      <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
    </item>
  </channel>
</rss>
EOF

    log_info "Appcast.xml generated successfully"
}

# Validate appcast.xml
validate_appcast() {
    log_step "Validating appcast.xml..."

    if command -v xmllint &> /dev/null; then
        if xmllint --noout "$APPCAST_FILE" 2>/dev/null; then
            log_info "✅ Appcast.xml is valid XML"
        else
            log_error "❌ Appcast.xml is invalid XML"
            exit 1
        fi
    else
        log_warn "xmllint not available for validation"
    fi
}

# Display information
display_info() {
    log_info "🎉 Appcast generation completed!"
    echo
    log_info "Generated files:"
    log_info "  - Appcast: $APPCAST_FILE"
    log_info "  - Backup: ${APPCAST_FILE}.backup (if existed)"
    echo
    log_info "Release information:"
    log_info "  - Version: $VERSION (Build $BUILD)"
    log_info "  - DMG: $DMG_NAME-$VERSION.dmg"
    log_info "  - Size: $DMG_SIZE bytes"
    log_info "  - Download URL: $DOWNLOAD_URL"
    echo
    log_info "Next steps:"
    log_info "1. Upload DMG to GitHub releases"
    log_info "2. Upload appcast.xml to your website"
    log_info "3. Test the update mechanism"
    echo

    if [[ "$SIGNATURE" == "PLACEHOLDER_SIGNATURE" ]]; then
        log_warn "⚠️  Important: The signature is a placeholder!"
        log_info "To generate a proper signature:"
        log_info "1. Install Sparkle tools"
        log_info "2. Run: sign_update $BUILD_DIR/$DMG_NAME-$VERSION.dmg"
        log_info "3. Update the sparkle:edSignature in appcast.xml"
        log_info "4. Re-upload appcast.xml to your website"
    else
        log_info "✅ Signature generated and included in appcast.xml"
    fi
}

# Main execution
main() {
    log_info "Starting MindMic appcast generation..."
    log_info "Version: $VERSION (Build $BUILD)"

    check_dependencies
    get_dmg_info
    generate_signature
    backup_appcast
    generate_appcast
    validate_appcast
    display_info
}

# Handle script interruption
trap 'log_error "Script interrupted"; exit 1' INT TERM

# Check for command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version)
            VERSION="$2"
            shift 2
            ;;
        -b|--build)
            BUILD="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -v, --version VERSION    Set version (default: 2.0)"
            echo "  -b, --build BUILD        Set build number (default: 160)"
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