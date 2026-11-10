#!/usr/bin/env python3
"""Prepare a free release without development profiles or restricted entitlements."""

import pathlib
import plistlib
import subprocess
import sys
import tempfile

app = pathlib.Path(sys.argv[1]).resolve()
source_entitlements = pathlib.Path(sys.argv[2])
if not (app / "Contents/Info.plist").is_file():
    raise SystemExit(f"Not an app bundle: {app}")

# These permissions work without a provisioning profile. Never copy developer
# identity, keychain groups, or debugging entitlements into a free release.
allowed = {
    "com.apple.security.app-sandbox",
    "com.apple.security.automation.apple-events",
    "com.apple.security.device.audio-input",
    "com.apple.security.screen-capture",
    "com.apple.security.files.user-selected.read-only",
    "com.apple.security.network.client",
    "com.apple.security.network.server",
}

for profile in app.rglob("embedded.provisionprofile"):
    profile.unlink()

def entitlements(path):
    if path == app:
        return plistlib.loads(source_entitlements.read_bytes())
    result = subprocess.run(
        ["codesign", "--display", "--entitlements", "-", str(path)],
        capture_output=True,
    )
    return plistlib.loads(result.stdout) if result.stdout.strip() else {}

# Sign the innermost code first, then its containing bundles. Applying --deep
# with the main app's entitlements would give them to every Sparkle helper too.
code = []
for path in app.rglob("*"):
    if path.is_symlink():
        continue
    if path.is_dir() and path.suffix in {".app", ".framework", ".xpc"}:
        code.append(path)
    elif path.is_file():
        with path.open("rb") as handle:
            magic = handle.read(4)
        if magic in {b"\xcf\xfa\xed\xfe", b"\xce\xfa\xed\xfe", b"\xca\xfe\xba\xbe", b"\xca\xfe\xba\xbf"}:
            code.append(path)
code.append(app)

# Snapshot entitlements before signing inner executables changes bundle signatures.
permissions = {path: {k: v for k, v in entitlements(path).items() if k in allowed} for path in code}
with tempfile.TemporaryDirectory() as temp:
    ent = pathlib.Path(temp) / "release.entitlements"
    for path in sorted(code, key=lambda p: len(p.parts), reverse=True):
        ent.write_bytes(plistlib.dumps(permissions[path]))
        subprocess.run(
            ["codesign", "--force", "--sign", "-", "--entitlements", str(ent), str(path)],
            check=True,
        )

subprocess.run(["codesign", "--verify", "--deep", "--strict", "--verbose=2", str(app)], check=True)
