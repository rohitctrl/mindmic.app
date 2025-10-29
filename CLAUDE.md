# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**MindMic** is a macOS voice transcription application built with SwiftUI and Swift. It provides real-time audio recording, transcription using local Whisper models and cloud AI services, and AI-powered text enhancement. The app integrates deeply with macOS system features including accessibility, screen capture, and hotkey management.

## Development Commands

```bash
# Open project in Xcode
open mindmic.xcodeproj

# Build from command line (requires Xcode command line tools)
xcodebuild -project mindmic.xcodeproj -scheme mindmic build

# Archive for distribution
xcodebuild -project mindmic.xcodeproj -scheme mindmic archive

# Run tests
xcodebuild test -project mindmic.xcodeproj -scheme mindmic -destination 'platform=macOS'

# Git operations
git status                          # Check current status
git add -A                          # Stage all changes
git commit -m "commit message"      # Commit changes
git push origin main               # Push to GitHub
```

## Architecture Overview

### Core Application Structure
- **Main Entry**: `mindmic.swift` - SwiftUI app entry point with multiple scenes and services
- **AppDelegate**: Handles application lifecycle, file opening, and activation policy management
- **MenuBar Integration**: Menu bar extra with toggle functionality between full app and menu bar only modes

### Key Directories
```
mindmic/
├── Services/          # Core business logic services
├── Views/            # SwiftUI views and UI components
├── Whisper/          # Whisper integration and model management
├── Models/           # Data models and SwiftData configurations
├── PowerMode/        # Power mode features and app integration
├── Resources/        # App assets and resources
└── Notifications/    # System notification management
```

### Core Services Architecture

#### Audio Recording & Processing
- **Recorder.swift**: Core audio recording with AVAudioRecorder, device management, and audio metering
- **AudioDeviceManager**: Manages microphone device selection and configuration
- **AudioFileTranscriptionService**: Handles file-based transcription workflows
- **LocalTranscriptionService**: Whisper-based local transcription
- **CloudTranscriptionService**: Multiple cloud AI provider integrations

#### AI Integration
- **AIService.swift**: Multi-provider AI service (OpenAI, Anthropic, Gemini, GROQ, Mistral, Ollama, ElevenLabs, Deepgram)
- **AIEnhancementService**: AI-powered text enhancement and post-processing
- **WhisperState.swift**: Core Whisper model management and transcription state

#### System Integration
- **HotkeyManager**: Global hotkey registration and management
- **MenuBarManager**: Menu bar interface and window management
- **ScreenCaptureService**: Context awareness through screen content analysis
- **NotificationManager**: System notification handling

## Technical Details

### Build System
- **Target**: macOS 14.0+ minimum system requirement
- **Frameworks**:
  - Whisper.xcframework (local transcription)
  - Sparkle (updates)
  - KeyboardShortcuts (hotkey management)
  - LaunchAtLogin (autostart)
  - FluidAudio (audio processing)

### Data Persistence
- **SwiftData**: Primary data persistence with custom storage location in `~/Library/Application Support/com.rohitk.mindmic/`
- **Temporary Files**: Audio files are temporary with auto-cleanup options
- **Configuration**: User preferences and app state management

### Threading Patterns
- **MainActor**: UI updates properly isolated to main thread
- **Async/Await**: Proper async patterns for background operations
- **OSLog**: Subsystem logging throughout the application

### Security & Permissions
- **Entitlements**: Defined in `mindmic.entitlements` including audio input and screen capture
- **Info.plist**: Document types, screen capture description, update feed configuration
- **App Permissions**: Microphone access, screen capture, network client/server, Apple Events, file access

## Key Features

### Power Mode
- Enhanced transcription with context awareness
- Integration with active applications and browser content
- Automatic audio cleanup and transcription management

### Multi-Provider AI Support
- 11 different AI providers with configurable models
- Fallback mechanisms and transcription retry logic
- Custom provider configuration support

### Hotkey System
- Multiple configurable global hotkeys
- Middle-click activation with delay settings
- System-wide accessibility integration

## Development Guidelines

### Code Architecture Patterns
- **MVVM Pattern**: Heavy use of SwiftUI with ObservableObject
- **Dependency Injection**: Services initialized with proper dependencies
- **Service Layer**: Well-defined service separation for audio, AI, and system integration

### Important Implementation Notes
- **Whisper Integration**: Local Whisper models in `whisper.cpp/` directory with pre-built XCFramework
- **Updates**: Sparkle-based update system with silent background checking (current version 1.59)
- **Privacy**: Temporary audio storage with configurable retention policies
- **Multi-language Support**: Extensive localization throughout the application

### Core Service Dependencies
When working with the codebase, understand these key service relationships:
- **AudioDeviceManager** → **Recorder** → **TranscriptionService** → **AIEnhancementService**
- **WhisperState** coordinates local transcription model management
- **ScreenCaptureService** provides context for Power Mode features
- **HotkeyManager** and **MenuBarManager** coordinate user interaction patterns

## Project Maintenance

### Repository Cleanliness
- **No development scripts**: Debug scripts and setup files should not be committed
- **No build artifacts**: Xcode user data (`xcuserdata/`) and shared data (`xcshareddata/`) are gitignored
- **No temporary files**: `.DS_Store`, `.env.template`, and tracking files should not be committed
- **Clean documentation**: Keep only essential documentation in the repository

### File Structure Guidelines
- **Core code only**: Only commit production-ready application code
- **Essential docs**: Keep `CLAUDE.md`, `README.md` if exists, and API documentation
- **No testing scripts**: Debug and testing Swift scripts should be removed after use
- **No setup guides**: Temporary setup documentation should not be committed

### Git Workflow
- **Main branch**: Primary development branch
- **Clean commits**: Use descriptive commit messages with proper formatting
- **Regular cleanup**: Remove unnecessary files and directories after development phases
- **Version control**: Ensure only essential files are tracked in version control