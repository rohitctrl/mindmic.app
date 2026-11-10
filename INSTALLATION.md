# Install MindMic

MindMic supports Apple Silicon Macs (M1 or newer) running macOS 14 or later.
Intel Macs are not supported. Distribution is free, with an ad-hoc code signature
and no Apple notarization. First launch requires your approval in System Settings.

## Homebrew

With Homebrew installed, run:

```bash
brew install --cask rohitctrl/tap/mindmic
```

If Terminal says `brew: command not found`, install Homebrew from
[brew.sh](https://brew.sh) and follow the installer's **Next steps** to add it to
Terminal's PATH. On Apple Silicon, an existing Homebrew installation can be loaded
into the current Terminal session with:

```bash
eval "$(/opt/homebrew/bin/brew shellenv)"
```

## First launch

1. Open **MindMic** from Applications.
2. If macOS says Apple could not verify the app, dismiss the message.
3. Open **System Settings → Privacy & Security** and click **Open Anyway** for MindMic.
4. Confirm the approval, then grant microphone access when requested.

Screen recording is needed for screen context features; Accessibility is needed
for features that insert text into other apps. Grant these when using those features.
A new version may require approval again.

A message saying the app **contains malware**, was automatically moved to the Bin,
or is **damaged** is not the expected approval prompt. Leave that copy closed and
[report the exact message](https://github.com/rohitctrl/mindmic.app/issues).

## Updating or replacing v2.0.4

The old v2.0.4 download contained a development provisioning profile that expired.
It could be installed successfully by Homebrew and then fail to launch. Releases
from v2.0.5 remove that dependency and verify the packaged app's signature and launch.

```bash
brew update
brew upgrade --cask rohitctrl/tap/mindmic
```

If macOS already moved the old app to the Bin, reinstall the current cask:

```bash
brew reinstall --cask rohitctrl/tap/mindmic
```

Follow the first-launch approval steps above. Reinstalling preserves your
transcription data and preferences; do not use `--zap` when replacing the app.
Check the installed version with `brew info --cask mindmic`.

## Manual download

Download the DMG from [GitHub Releases](https://github.com/rohitctrl/mindmic.app/releases/latest),
open it, and drag **MindMic.app** into Applications. Then follow the first-launch steps.
The filename includes the version, such as `MindMic-2.0.5-unsigned.dmg`.
The `unsigned` filename is retained for compatibility; the app is ad-hoc signed.

Each release includes `checksums.txt`. To check a download:

```bash
shasum -a 256 ~/Downloads/MindMic-2.0.5-unsigned.dmg
```

A matching checksum confirms the file matches the release. It is not a malware scan.

## Uninstalling

```bash
brew uninstall --cask mindmic
```

## Diagnosing a launch failure

Include your macOS version (`sw_vers`) and `brew info --cask mindmic` when reporting
an issue. These checks do not launch the app or change system security settings:

```bash
codesign --verify --deep --strict --verbose=2 /Applications/MindMic.app
/usr/bin/log show --last 30m --style compact --predicate 'eventMessage CONTAINS[c] "mindmic"'
```

If the app has already been moved to the Bin, the signature check will report that
the Applications path does not exist. The log command can still show the failure.
Review logs for personal paths before sharing them.
