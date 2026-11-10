#!/usr/bin/env python3
"""Fail release validation for the signing defect that broke Homebrew installs."""

import pathlib
import plistlib
import subprocess
import sys

app = pathlib.Path(sys.argv[1]).resolve()
subprocess.run(["codesign", "--verify", "--deep", "--strict", "--verbose=2", str(app)], check=True)
profiles = list(app.rglob("*.provisionprofile"))
if profiles:
    raise SystemExit(f"Unexpected provisioning profiles: {profiles}")
info = plistlib.loads((app / "Contents/Info.plist").read_bytes())
executable = app / "Contents/MacOS" / info["CFBundleExecutable"]
archs = subprocess.check_output(["lipo", "-archs", str(executable)], text=True).split()
if "arm64" not in archs:
    raise SystemExit(f"Missing Apple Silicon executable: {archs}")

for path in [app, *app.rglob("*")]:
    if path.is_symlink() or not (path.is_file() or path.suffix in {".app", ".framework", ".xpc"}):
        continue
    if path.is_file():
        with path.open("rb") as handle:
            if handle.read(4) not in {b"\xcf\xfa\xed\xfe", b"\xce\xfa\xed\xfe", b"\xca\xfe\xba\xbe", b"\xca\xfe\xba\xbf"}:
                continue
    result = subprocess.run(["codesign", "--display", "--entitlements", "-", "--xml", str(path)], capture_output=True)
    if result.stdout.strip():
        ent = plistlib.loads(result.stdout)
        forbidden = [key for key in ent if key.startswith("com.apple.developer.") or key in {
            "keychain-access-groups", "com.apple.application-identifier", "application-identifier",
            "com.apple.security.get-task-allow", "get-task-allow",
        }]
        if forbidden:
            raise SystemExit(f"Profile-dependent or debug entitlements in {path}: {forbidden}")
signature = subprocess.run(["codesign", "-dv", str(app)], capture_output=True, text=True, check=True)
if "Signature=adhoc" not in signature.stderr:
    raise SystemExit("Free release must use an ad-hoc signature")
print(f"Verified {info['CFBundleShortVersionString']}: arm64, ad-hoc, no provisioning profiles or restricted entitlements")
