# MindMic signing and first-launch approval

## Why does macOS ask for approval?

MindMic uses an **ad-hoc signature**: it seals the app's contents without an
Apple-issued Developer ID certificate. It is not notarized by Apple. This keeps
distribution free, but Gatekeeper cannot verify the developer's identity.

Open MindMic once, then use **System Settings → Privacy & Security → Open Anyway**.
See the [installation guide](INSTALLATION.md) for the full steps.

## Does every security warning mean the same thing?

No. An inability to verify the developer is the expected first-launch approval
case. **Contains malware**, **damaged**, automatic removal, and invalid signatures
need investigation. Do not dismiss them as normal merely because MindMic is open
source. Report the wording and version at
[GitHub Issues](https://github.com/rohitctrl/mindmic.app/issues).

## What went wrong with v2.0.4?

That release retained an expiring development provisioning profile and restricted
entitlements. The profile expired, so macOS refused to start the executable.
A successful Homebrew installation only meant the app had been copied.

The replacement build removes development profiles, signs nested components and
the app with ad-hoc signatures, and checks for profile-dependent entitlements.
Release checks install the packaged DMG with Homebrew and test process startup
on macOS 15 and 26 after simulating the user's first-open approval in CI.
The cask itself does not remove quarantine or change security settings.

## Can the approval prompt be eliminated for free?

This distribution does not provide an Apple-notarized build. With standard macOS
security settings, approval remains necessary. A Developer ID-signed, notarized
release would require Apple Developer Program credentials.

## What does the checksum prove?

Homebrew checks the downloaded DMG against the cask's SHA256. This detects a
mismatched or corrupted download; it does not establish that software is harmless.

Apple explains the different alerts in
[Safely open apps on your Mac](https://support.apple.com/102445).
