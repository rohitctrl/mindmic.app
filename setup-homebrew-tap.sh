#!/bin/bash

# Homebrew Tap Setup Script for MindMic
# This script creates and configures a personal Homebrew tap

set -e  # Exit on any error

# Configuration
TAP_NAME="homebrew-tap"
GITHUB_USERNAME="rohitctrl"  # Update this with your actual GitHub username
TAP_REPO="${GITHUB_USERNAME}/${TAP_NAME}"
CASK_NAME="mindmic"

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

    # Check for git
    if ! command -v git &> /dev/null; then
        log_error "git not found. Please install Git."
        exit 1
    fi

    # Check for gh CLI (optional but recommended)
    if ! command -v gh &> /dev/null; then
        log_warn "GitHub CLI (gh) not found. Manual GitHub setup required."
        log_info "Install GitHub CLI from: https://cli.github.com/"
    else
        log_info "GitHub CLI found. Will use for repository creation."
    fi

    log_info "Dependencies checked."
}

# Validate GitHub username
validate_github_username() {
    log_info "Validating GitHub username configuration..."

    if [ -z "$GITHUB_USERNAME" ] || [ "$GITHUB_USERNAME" = "your-username" ]; then
        log_error "Please update GITHUB_USERNAME in this script with your actual GitHub username"
        log_info "Edit this file and change: GITHUB_USERNAME=\"your-username\""
        exit 1
    fi

    log_info "GitHub username: $GITHUB_USERNAME"
}

# Create local tap directory
create_local_tap() {
    log_step "Creating local tap directory..."

    if [ -d "$TAP_NAME" ]; then
        log_warn "Tap directory '$TAP_NAME' already exists"
        read -p "Do you want to remove it and recreate? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$TAP_NAME"
            log_info "Removed existing tap directory"
        else
            log_info "Using existing tap directory"
            return 0
        fi
    fi

    mkdir -p "$TAP_NAME/Casks"
    log_info "✅ Created local tap directory: $TAP_NAME/Casks"
}

# Create MindMic cask formula
create_cask_formula() {
    log_step "Creating MindMic cask formula..."

    CASK_FILE="$TAP_NAME/Casks/${CASK_NAME}.rb"

    cat > "$CASK_FILE" << 'EOF'
cask "mindmic" do
  version "2.0"
  sha256 :no_check  # Will be updated with actual SHA256 during release

  url "https://github.com/rohitctrl/mindmic.app/releases/download/v#{version}/MindMic-#{version}-unsigned.dmg"
  name "MindMic"
  desc "AI-powered voice transcription and enhancement application"
  homepage "https://github.com/rohitctrl/mindmic.app"

  app "MindMic.app"

  zap trash: [
    "~/Library/Application Support/com.rohitk.mindmic",
    "~/Library/Preferences/com.rohitk.Mindmic.plist",
    "~/Library/Caches/com.rohitk.Mindmic",
    "~/Library/WebKit/com.rohitk.mindmic",
  ]
end
EOF

    log_info "✅ Created cask formula: $CASK_FILE"
}

# Create README for tap
create_tap_readme() {
    log_step "Creating README for tap..."

    README_FILE="$TAP_NAME/README.md"

    cat > "$README_FILE" << EOF
# $GITHUB_USERNAME's Homebrew Tap

This repository contains Homebrew formulae for macOS applications that aren't available in Homebrew core.

## Available Formulae

### MindMic

AI-powered voice transcription and enhancement application.

#### Installation

\`\`\`bash
brew tap $TAP_REPO
brew install --cask $CASK_NAME
\`\`\`

#### Usage

After installation, you can launch MindMic from your Applications folder or via Spotlight search.

**Important:** MindMic is distributed as an unsigned application. On first launch, you'll need to:

1. Open MindMic once. macOS says it can't verify the app: click Done
2. System Settings > Privacy & Security > click "Open Anyway" next to MindMic
3. If it says the app is "damaged", run: xattr -dr com.apple.quarantine /Applications/MindMic.app
4. Grant microphone and screen recording permissions when prompted

#### Update

\`\`\`bash
brew upgrade --cask $CASK_NAME
\`\`\`

#### Uninstall

\`\`\`bash
brew uninstall --cask $CASK_NAME
\`\`\`

## About Unsigned Applications

This tap distributes unsigned applications to avoid the Apple Developer Program fee. While this makes the software freely available, it means:

- macOS will show security warnings on first launch
- You must manually grant permissions to the application
- Updates must be installed manually via Homebrew

These warnings are normal and don't indicate malicious software. The source code is publicly available for review.

## Support

For issues with MindMic itself, please visit the [main repository](https://github.com/rohitctrl/mindmic.app).

For issues with this Homebrew formula, please [file an issue](https://github.com/$TAP_REPO/issues).
EOF

    log_info "✅ Created README: $README_FILE"
}

# Create GitHub repository
create_github_repo() {
    log_step "Creating GitHub repository..."

    if command -v gh &> /dev/null; then
        # Use GitHub CLI
        cd "$TAP_NAME"

        if gh repo view "$TAP_REPO" &> /dev/null; then
            log_info "Repository already exists on GitHub"
        else
            log_info "Creating repository on GitHub..."
            gh repo create "$TAP_REPO" --public --description "Homebrew tap for MindMic and other macOS applications" --clone=false
            log_info "✅ Repository created: https://github.com/$TAP_REPO"
        fi

        cd ..
    else
        log_warn "GitHub CLI not available. Manual repository creation required:"
        log_info "1. Visit: https://github.com/new"
        log_info "2. Repository name: $TAP_NAME"
        log_info "3. Description: Homebrew tap for MindMic and other macOS applications"
        log_info "4. Make it Public"
        log_info "5. Don't initialize with README (we already have one)"
        log_info "6. Click 'Create repository'"
        echo
        log_info "Then run these commands:"
        log_info "cd $TAP_NAME"
        log_info "git init"
        log_info "git add ."
        log_info "git commit -m 'Initial commit with MindMic cask'"
        log_info "git branch -M main"
        log_info "git remote add origin https://github.com/$TAP_REPO.git"
        log_info "git push -u origin main"
        log_info "cd .."
    fi
}

# Initialize git repository
init_git_repo() {
    log_step "Initializing git repository..."

    cd "$TAP_NAME"

    # Initialize if not already a git repo
    if [ ! -d ".git" ]; then
        git init
        log_info "✅ Initialized git repository"
    fi

    # Add all files
    git add .
    git commit -m "Initial commit with MindMic cask formula

- Add MindMic cask for unsigned distribution
- Include installation and usage documentation
- Support for automatic updates via Homebrew"

    # Set up remote if GitHub CLI is available
    if command -v gh &> /dev/null; then
        git branch -M main
        git remote add origin "https://github.com/$TAP_REPO.git" 2>/dev/null || true

        if ! git remote get-url origin &> /dev/null; then
            log_warn "Could not set up remote. Manual push required."
        else
            log_info "✅ Git repository configured with remote"
        fi
    fi

    cd ..
}

# Push to GitHub (if possible)
push_to_github() {
    if command -v gh &> /dev/null && [ -d "$TAP_NAME/.git" ]; then
        log_step "Pushing to GitHub..."

        cd "$TAP_NAME"

        if git remote get-url origin &> /dev/null; then
            git push -u origin main
            log_info "✅ Pushed to GitHub: https://github.com/$TAP_REPO"
        else
            log_warn "Remote not configured. Manual push required."
        fi

        cd ..
    else
        log_info "Skipping GitHub push (GitHub CLI not available or git not initialized)"
    fi
}

# Create update script for releases
create_update_script() {
    log_step "Creating update script for releases..."

    UPDATE_SCRIPT="$TAP_NAME/update-cask.sh"

    cat > "$UPDATE_SCRIPT" << 'EOF'
#!/bin/bash

# Update MindMic cask formula with new version and checksum

set -e

CASK_NAME="mindmic"
VERSION=$1
SHA256=$2

if [ -z "$VERSION" ] || [ -z "$SHA256" ]; then
    echo "Usage: ./update-cask.sh VERSION SHA256"
    echo "Example: ./update-cask.sh 2.0 abc123def456..."
    exit 1
fi

echo "Updating $CASK_NAME cask to version $VERSION"

# Update the cask file
sed -i '' "s/version \"[^\"]*\"/version \"$VERSION\"/" "Casks/$CASK_NAME.rb"
sed -i '' "s/sha256 :no_check/sha256 \"$SHA256\"/" "Casks/$CASK_NAME.rb"

echo "Updated version to $VERSION"
echo "Updated SHA256 to $SHA256"

# Commit and push
git add "Casks/$CASK_NAME.rb"
git commit -m "Update $CASK_NAME to version $VERSION"
git push

echo "✅ Cask updated and pushed to GitHub"
echo "Users can update with: brew upgrade --cask $CASK_NAME"
EOF

    chmod +x "$UPDATE_SCRIPT"
    log_info "✅ Created update script: $UPDATE_SCRIPT"
}

# Display final information
display_final_info() {
    log_info "🎉 Homebrew tap setup completed!"
    echo
    log_info "📦 Tap Information:"
    log_info "  - Repository: https://github.com/$TAP_REPO"
    log_info "  - Tap name: $TAP_REPO"
    log_info "  - Cask: $CASK_NAME"
    echo

    log_info "🚀 Installation Instructions for Users:"
    log_info "  brew tap $TAP_REPO"
    log_info "  brew install --cask $CASK_NAME"
    echo

    log_info "📋 What was created:"
    log_info "  ✅ Local tap directory: $TAP_NAME/"
    log_info "  ✅ Cask formula: $TAP_NAME/Casks/$CASK_NAME.rb"
    log_info "  ✅ Documentation: $TAP_NAME/README.md"
    log_info "  ✅ Update script: $TAP_NAME/update-cask.sh"
    echo

    if command -v gh &> /dev/null; then
        log_info "🌐 GitHub repository created and pushed"
    else
        log_info "🌐 Manual GitHub setup required:"
        log_info "  1. Create repository at: https://github.com/new"
        log_info "  2. Name: $TAP_NAME"
        log_info "  3. Push the local repository"
    fi

    echo
    log_info "🔄 Update Process:"
    log_info "  1. Build new release: ./build-unsigned.sh"
    log_info "  2. Get SHA256 from checksums.txt"
    log_info "  3. Update cask: cd $TAP_NAME && ./update-cask.sh VERSION SHA256"
    echo

    log_info "⚠️  Important Notes:"
    log_info "  - Update GITHUB_USERNAME in this script if needed"
    log_info "  - The cask uses unsigned DMG distribution"
    log_info "  - Users will see Gatekeeper warnings (documented in README)"
    log_info "  - Test installation on a fresh system before release"
}

# Main execution
main() {
    log_info "Setting up Homebrew tap for MindMic..."
    log_info "GitHub username: $GITHUB_USERNAME"
    log_info "Tap repository: $TAP_REPO"
    echo

    check_dependencies
    validate_github_username
    create_local_tap
    create_cask_formula
    create_tap_readme
    create_github_repo
    init_git_repo
    push_to_github
    create_update_script
    display_final_info
}

# Handle script interruption
trap 'log_error "Script interrupted"; exit 1' INT TERM

# Run main function
main "$@"
