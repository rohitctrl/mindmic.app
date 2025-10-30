cask "mindmic" do
  version "2.0"
  sha256 :no_check  # Will be updated with actual SHA256 during release

  url "https://github.com/rohit1906/mind-mic/releases/download/v#{version}/MindMic-#{version}-unsigned.dmg"
  name "MindMic"
  desc "AI-powered voice transcription and enhancement application"
  homepage "https://github.com/rohit1906/mind-mic"

  app "MindMic.app"

  # Uninstallation paths for clean removal
  zap trash: [
    "~/Library/Application Support/com.rohitk.mindmic",
    "~/Library/Preferences/com.rohitk.Mindmic.plist",
    "~/Library/Caches/com.rohitk.Mindmic",
    "~/Library/WebKit/com.rohitk.mindmic",
    "~/Library/Saved Application State/com.rohitk.mindmic.savedState",
    "~/Library/Logs/MindMic",
  ]

  # Post-install information for users
  caveats <<~EOS
    #{token} is distributed as an unsigned application to avoid Apple Developer fees.

    IMPORTANT FIRST LAUNCH INSTRUCTIONS:
    1. After installation, find MindMic in your Applications folder
    2. Right-click on MindMic.app and select "Open" (don't double-click)
    3. Click "Open" in the security dialog that appears
    4. Grant microphone and screen recording permissions when prompted

    This security warning is normal for unsigned apps and doesn't indicate malware.
    The source code is publicly available for review at #{homepage}.

    For help with installation, visit:
    https://github.com/rohit1906/mind-mic/blob/main/INSTALLATION.md
  EOS
end