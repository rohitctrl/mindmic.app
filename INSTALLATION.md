# MindMic Installation Guide

This guide covers all methods for installing MindMic on macOS. MindMic is distributed as an unsigned application to avoid Apple Developer fees, which means you'll see security warnings during installation - this is normal and safe.

## System Requirements

- **macOS 14.0 or later** (Sonoma or newer)
- **Apple Silicon Mac (M1 or newer)**
- **Microphone access** for voice recording
- **Screen recording permission** for Power Mode features

## Installation Methods

### Method 1: Homebrew (Recommended for Technical Users)

Homebrew provides the easiest installation and update experience.

#### Installation

```bash
# Add the tap repository
brew tap rohitctrl/homebrew-tap

# Install MindMic
brew install --cask mindmic
```

#### First Launch

1. Open Finder and go to Applications folder
2. Double-click MindMic.app. macOS says it can't verify the app. Click **Done**
3. Open **System Settings → Privacy & Security**, scroll down, and click **Open Anyway** next to the MindMic message
4. If macOS says the app is **"damaged"**, run `xattr -dr com.apple.quarantine /Applications/MindMic.app` in Terminal and open it again
5. Grant permissions when prompted:
   - Microphone access
   - Screen recording access (for Power Mode)

#### Updates

```bash
# Check for updates
brew upgrade --cask mindmic
```

#### Uninstallation

```bash
brew uninstall --cask mindmic
```

---

### Method 2: Direct Download (Manual Installation)

#### Step 1: Download

Visit the [GitHub Releases page](https://github.com/rohitctrl/mindmic.app/releases) and download the latest:
- `MindMic-2.0-unsigned.dmg` (recommended) or
- `MindMic-2.0-unsigned.zip`

#### Step 2: Verify Download (Optional but Recommended)

Check the SHA256 checksum matches the one in the release notes:

```bash
# For DMG
shasum -a 256 ~/Downloads/MindMic-2.0-unsigned.dmg

# For ZIP
shasum -a 256 ~/Downloads/MindMic-2.0-unsigned.zip
```

#### Step 3: Install

**Using DMG:**
1. Double-click the downloaded DMG file
2. Drag MindMic.app to your Applications folder
3. Eject the DMG

**Using ZIP:**
1. Double-click the ZIP file to extract it
2. Move MindMic.app to your Applications folder

#### Step 4: First Launch (Important!)

1. Open Finder → Applications folder
2. Double-click MindMic.app. macOS says it can't verify the app (*"Apple could not verify MindMic is free of malware"*). Click **Done**
3. Open **System Settings → Privacy & Security**, scroll down, and click **Open Anyway** next to the MindMic message
4. If macOS says the app is **"damaged"**, see Troubleshooting below
5. Grant permissions when prompted

---

## Understanding Security Warnings

### Why Do I See Security Warnings?

MindMic is distributed as an **unsigned application** to avoid the $99/year Apple Developer fee. This means:

- **Gatekeeper Warning**: macOS shows "can't be opened because Apple cannot check it for malicious software"
- **This is normal** for unsigned applications
- **This does not indicate malware** - the app is safe and open source

### How to Bypass Security Warnings

**Method 1: System Settings (works on every macOS version)**
1. Try to open MindMic.app (you'll see the warning)
2. Open System Settings → Privacy & Security
3. Find the security section about MindMic
4. Click "Open Anyway" and confirm with your password

> On macOS 15 (Sequoia) and later, right-click → Open no longer bypasses this check. Use Open Anyway.

**Method 2: Terminal**
```bash
xattr -dr com.apple.quarantine /Applications/MindMic.app
```

### After First Launch

Once you've successfully opened MindMic using one of these methods, macOS will remember your choice and you can launch it normally (double-click) in the future.

## Granting Permissions

MindMic requires several permissions to function properly:

### Microphone Access

1. When you first try to record, macOS will ask for microphone access
2. Click "OK" to grant access
3. If you accidentally clicked "Don't Allow":
   - Go to System Settings → Privacy & Security → Microphone
   - Find MindMic and enable the toggle

### Screen Recording (Power Mode)

1. Power Mode requires screen recording to analyze active applications
2. When you first enable Power Mode, macOS will ask for screen recording permission
3. Click "Open System Settings" or "Open System Preferences"
4. Find MindMic in the Screen Recording list and enable it
5. Restart MindMic after granting permission

### Apple Events

MindMic uses Apple Events to integrate with browsers and other applications. This is usually granted automatically, but if you encounter issues:

1. Go to System Settings → Privacy & Security → Automation
2. Find MindMic and enable the necessary applications

## Troubleshooting

### App Won't Open

**Problem**: "MindMic.app can't be opened because Apple cannot check it for malicious software"

**Solution**:
1. Open System Settings → Privacy & Security and click "Open Anyway" next to the MindMic message
2. If it says the app is "damaged", run `xattr -dr com.apple.quarantine /Applications/MindMic.app` and open it again
3. This is only required on first launch

### Permission Issues

**Problem**: Microphone or screen recording not working

**Solution**:
1. Go to System Settings → Privacy & Security
2. Find the relevant permission (Microphone, Screen Recording)
3. Enable MindMic
4. Restart the app

### App Crashes on Launch

**Problem**: App crashes immediately after opening

**Solutions**:
1. **Check macOS version**: Ensure you're running macOS 14.0 or later
2. **Check architecture**: MindMic is optimized for Apple Silicon (M1/M2/M3)
3. **Reset permissions**: Remove from Applications and reinstall
4. **Check logs**: Open Console.app and look for MindMic errors

### Homebrew Installation Fails

**Problem**: `brew install --cask mindmic` fails

**Solutions**:
1. **Update Homebrew**: `brew update && brew upgrade`
2. **Check tap**: `brew tap rohitctrl/homebrew-tap`
3. **Check internet connection**: Ensure you can access GitHub
4. **Try manual installation**: Use direct download method

### DMG Won't Mount

**Problem**: Downloaded DMG shows as damaged

**Solutions**:
1. **Redownload**: The file may be corrupted
2. **Check checksum**: Verify SHA256 matches release notes
3. **Try ZIP version**: Download the ZIP instead of DMG

## Advanced Installation

### Building from Source

If you want to build MindMic yourself:

```bash
# Clone the repository
git clone https://github.com/rohitctrl/mindmic.app.git
cd mindmic.app

# Open in Xcode
open mindmic.xcodeproj

# Build and run from Xcode
# Or use command line:
xcodebuild -project mindmic.xcodeproj -scheme mindmic -configuration Release build
```

### Command Line Usage

After installation via Homebrew, you can also use command line tools:

```bash
# Check if MindMic is properly installed
brew list --cask | grep mindmic

# Get installation information
brew info --cask mindmic
```

## Verification and Security

### Verifying Download Integrity

Always verify your download using SHA256 checksums:

1. Go to the [GitHub Releases page](https://github.com/rohitctrl/mindmic.app/releases)
2. Copy the SHA256 checksum from the release notes
3. Run this command in Terminal:
   ```bash
   shasum -a 256 ~/Downloads/MindMic-2.0-unsigned.dmg
   ```
4. Compare the output with the checksum from the release notes

### Code Review

MindMic is open source! You can review the code at:
- **Main repository**: https://github.com/rohitctrl/mindmic.app
- **Issues and discussions**: https://github.com/rohitctrl/mindmic.app/issues

## Support

### Getting Help

- **Documentation**: Check the main README.md in the repository
- **Issues**: Report bugs at https://github.com/rohitctrl/mindmic.app/issues
- **Discussions**: Ask questions at https://github.com/rohitctrl/mindmic.app/discussions

### Contributing

If you experience issues and have solutions:
1. Check existing issues first
2. Create detailed bug reports
3. Include macOS version and error messages
4. Consider contributing fixes

## FAQ

**Q: Is MindMic safe to use?**
A: Yes! MindMic is open source and the code is publicly available for review. The security warnings are due to unsigned distribution, not malicious software.

**Q: Why isn't MindMic signed?**
A: Apple Developer Program costs $99/year. Unsigned distribution allows MindMic to be available for free.

**Q: Will this affect my computer's security?**
A: No. MindMic only requests permissions it needs for transcription and enhancement features.

**Q: How do updates work?**
A: With Homebrew: `brew upgrade --cask mindmic`. With manual installation: download new versions from GitHub releases.

**Q: Can I use this on an Intel Mac?**
A: Not with the current build. Releases are Apple Silicon only (M1 or newer), macOS 14.0+.

---

**Thank you for installing MindMic!** If you find the app useful, consider starring the repository on GitHub or contributing to the project.