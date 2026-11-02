name: Test Homebrew Cask

on:
  push:
    paths:
      - ".github/workflows/test.yml"
  workflow_dispatch:

jobs:
  test-cask:
    name: Test brew cask install
    runs-on: macos-latest
    steps:
      - name: Add the MindMic tap
        run: brew tap rohitctrl/homebrew-tap

      - name: Trust and install the MindMic cask
        run: |
          brew trust --cask rohitctrl/tap/mindmic
          brew install --cask mindmic

      - name: Verify installation
        run: |
          brew list --cask
          ls -la /Applications/MindMic.app
