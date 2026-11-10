#!/usr/bin/env python3
"""Keep the cask URL, bundle name and checksum tied to the packaged artifact."""

import json
import pathlib
import re
import sys

release = json.loads(pathlib.Path(sys.argv[1]).read_text())
version, sha = release["version"], release["dmg_sha256"]
if not re.fullmatch(r"\d+\.\d+\.\d+", version) or not re.fullmatch(r"[0-9a-f]{64}", sha):
    raise SystemExit("Invalid release version or checksum")
name = f"MindMic-{version}-unsigned.dmg"
if release["dmg_name"] != name:
    raise SystemExit("Unexpected release asset name")
url = sys.argv[3] if len(sys.argv) > 3 else f"https://github.com/rohitctrl/mindmic.app/releases/download/v{version}/{name}"
if any(c in url for c in '\n\r"\\'):
    raise SystemExit("Invalid cask URL")
destination = pathlib.Path(sys.argv[2])
destination.parent.mkdir(parents=True, exist_ok=True)
destination.write_text(f'''cask "mindmic" do
  version "{version}"
  sha256 "{sha}"

  url "{url}"
  name "MindMic"
  desc "AI-powered voice transcription and enhancement"
  homepage "https://github.com/rohitctrl/mindmic.app"

  depends_on arch: :arm64
  depends_on macos: ">= :sonoma"

  app "MindMic.app"

  zap trash: [
    "~/Library/Application Support/com.rohitk.mindmic",
    "~/Library/Preferences/com.rohitk.Mindmic.plist",
    "~/Library/Caches/com.rohitk.Mindmic",
    "~/Library/WebKit/com.rohitk.mindmic",
  ]

  caveats <<~EOS
    MindMic is free and ad-hoc signed, without Apple notarization.
    On first launch, open MindMic, then go to System Settings > Privacy & Security
    and click Open Anyway. Grant microphone access when prompted.

    A "contains malware" or "damaged" message is not the expected approval prompt.
    Report it at https://github.com/rohitctrl/mindmic.app/issues.
  EOS
end
''')
