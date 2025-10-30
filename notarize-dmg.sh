#!/bin/bash

# MindMic Notarization Script
# This script notarizes the DMG for distribution

set -e  # Exit on any error

# Configuration
DMG_NAME="MindMic"
VERSION="2.0"
BUILD_DIR="build"
DMG_PATH="$BUILD_DIR/$DMG_NAME-$VERSION.dmg"
BUNDLE_ID="com.rohitk.mindmic"

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

# Check if DMG exists
check_dmg() {
    log_info "Checking for DMG file..."

    if [ ! -f "$DMG_PATH" ]; then
        log_error "DMG file not found at $DMG_PATH"
        log_error "Please run ./build-distribution.sh first"
        exit 1
    fi

    log_info "DMG file found: $DMG_PATH"
}

# Check for Apple ID and password
check_credentials() {
    log_info "Checking for Apple credentials..."

    if [ -z "$APPLE_ID" ]; then
        log_warn "APPLE_ID environment variable not set"
        log_info "You can set it with: export APPLE_ID=\"your-email@example.com\""
        echo
        read -p "Enter your Apple ID (Developer account email): " APPLE_ID
        export APPLE_ID
    fi

    if [ -z "$APPLE_ID_PASSWORD" ]; then
        log_warn "APPLE_ID_PASSWORD environment variable not set"
        log_info "You should use an app-specific password"
        log_info "Generate one at: https://appleid.apple.com/account/manage"
        echo
        read -s -p "Enter your app-specific password: " APPLE_ID_PASSWORD
        echo
        export APPLE_ID_PASSWORD
    fi

    if [ -z "$TEAM_ID" ]; then
        log_warn "TEAM_ID environment variable not set"
        echo
        read -p "Enter your Team ID (e.g., 353GDY5F9V): " TEAM_ID
        export TEAM_ID
    fi

    log_info "Credentials configured for Apple ID: $APPLE_ID"
    log_info "Team ID: $TEAM_ID"
}

# Upload for notarization
upload_for_notarization() {
    log_step "Uploading DMG for notarization..."

    # Create temporary file for notarization info
    NOTARIZATION_INFO_FILE="$BUILD_DIR/notarization_info.txt"

    # Upload for notarization
    xcrun altool \
        --notarize-app \
        --primary-bundle-id "$BUNDLE_ID" \
        --username "$APPLE_ID" \
        --password "$APPLE_ID_PASSWORD" \
        --asc-provider "$TEAM_ID" \
        --file "$DMG_PATH" \
        --output-format xml \
        > "$NOTARIZATION_INFO_FILE" 2>&1

    # Extract request UUID
    REQUEST_UUID=$(xmllint --xpath "//string/text()" "$NOTARIZATION_INFO_FILE" 2>/dev/null || echo "")

    if [ -z "$REQUEST_UUID" ]; then
        log_error "Failed to extract request UUID from notarization response"
        log_error "Check the notarization info file: $NOTARIZATION_INFO_FILE"
        cat "$NOTARIZATION_INFO_FILE"
        exit 1
    fi

    echo "$REQUEST_UUID" > "$BUILD_DIR/notarization_uuid.txt"
    log_info "Notarization uploaded successfully"
    log_info "Request UUID: $REQUEST_UUID"
}

# Check notarization status
check_notarization_status() {
    local request_uuid=$1
    log_step "Checking notarization status..."

    log_info "Checking status for UUID: $request_uuid"

    while true; do
        # Check status
        STATUS_OUTPUT="$BUILD_DIR/notarization_status.txt"
        xcrun altool \
            --notarization-info "$request_uuid" \
            --username "$APPLE_ID" \
            --password "$APPLE_ID_PASSWORD" \
            --output-format xml \
            > "$STATUS_OUTPUT" 2>&1

        # Parse status
        STATUS=$(xmllint --xpath "//key[text()='Status']/following-sibling::string[1]/text()" "$STATUS_OUTPUT" 2>/dev/null || echo "")

        case "$STATUS" in
            "success")
                log_info "✅ Notarization successful!"
                return 0
                ;;
            "invalid")
                log_error "❌ Notarization failed - invalid package"
                cat "$STATUS_OUTPUT"
                return 1
                ;;
            "rejected")
                log_error "❌ Notarization failed - rejected"
                cat "$STATUS_OUTPUT"
                return 1
                ;;
            *)
                if [ -n "$STATUS" ]; then
                    log_info "Status: $STATUS"
                fi
                log_info "Still processing... checking again in 30 seconds"
                sleep 30
                ;;
        esac
    done
}

# Download notarization ticket
download_notarization_ticket() {
    log_step "Downloading notarization ticket..."

    # Create temporary directory for ticket
    TICKET_DIR="$BUILD_DIR/ticket"
    mkdir -p "$TICKET_DIR"

    # Download notarization log
    xcrun altool \
        --notarization-history 0 \
        --username "$APPLE_ID" \
        --password "$APPLE_ID_PASSWORD" \
        --output-format xml \
        > "$BUILD_DIR/notarization_history.txt" 2>/dev/null

    log_info "Notarization ticket downloaded to $TICKET_DIR"
    log_info "You can view detailed logs in the notarization history file"
}

# Staple the DMG
staple_dmg() {
    log_step "Stapling notarization ticket to DMG..."

    xcrun stapler staple "$DMG_PATH"

    if [ $? -eq 0 ]; then
        log_info "✅ DMG stapled successfully"

        # Verify staple
        xcrun stapler validate "$DMG_PATH"

        if [ $? -eq 0 ]; then
            log_info "✅ Staple validated successfully"
        else
            log_warn "Staple validation failed (non-critical)"
        fi
    else
        log_error "❌ Failed to staple DMG"
        exit 1
    fi
}

# Display final information
display_final_info() {
    log_info "🎉 Notarization process completed successfully!"
    echo
    log_info "Final artifacts:"
    log_info "  - Notarized DMG: $DMG_PATH"
    log_info "  - Archive: $BUILD_DIR/mindmic.xcarchive"
    echo
    log_info "Your app is ready for distribution!"
    log_info "You can now:"
    log_info "  1. Upload the DMG to GitHub releases"
    log_info "  2. Update your appcast.xml"
    log_info "  3. Distribute to users"
}

# Main execution
main() {
    log_info "Starting MindMic notarization process..."
    log_info "DMG: $DMG_PATH"
    log_info "Bundle ID: $BUNDLE_ID"

    check_dmg
    check_credentials

    # Check if we already have a UUID (resuming)
    if [ -f "$BUILD_DIR/notarization_uuid.txt" ]; then
        REQUEST_UUID=$(cat "$BUILD_DIR/notarization_uuid.txt")
        log_info "Resuming notarization with UUID: $REQUEST_UUID"
    else
        upload_for_notarization
        REQUEST_UUID=$(cat "$BUILD_DIR/notarization_uuid.txt")
    fi

    check_notarization_status "$REQUEST_UUID"
    download_notarization_ticket
    staple_dmg
    display_final_info
}

# Handle script interruption
trap 'log_error "Script interrupted"; exit 1' INT TERM

# Run main function
main "$@"