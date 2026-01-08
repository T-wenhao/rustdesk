# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Core Build Commands
- `cargo run` - Build and run the desktop application (requires libsciter library for legacy UI)
- `cargo build --release` - Build Rust binary in release mode
- `cargo build --features <feature>` - Build with specific features
- `VCPKG_ROOT=$HOME/vcpkg cargo run` - Build with vcpkg dependencies

### Flutter Build Commands
- `python3 build.py --flutter` - Build Flutter version (desktop)
- `python3 build.py --flutter --release` - Build Flutter version in release mode
- `cd flutter && flutter build android` - Build Android APK
- `cd flutter && flutter build ios` - Build iOS app
- `cd flutter && flutter run` - Run Flutter app in development mode

### Feature-Specific Builds
- `python3 build.py --hwcodec` - Build with hardware codec support
- `python3 build.py --vram` - Build with VRAM feature (Windows only)
- `cargo build --features flutter` - Build with Flutter bridge support
- `cargo build --features unix-file-copy-paste` - Build with Unix file clipboard support

### Testing Commands
- `cargo test` - Run Rust tests
- `cd flutter && flutter test` - Run Flutter tests
- `cargo test --features <feature>` - Test with specific features

### Platform-Specific Scripts
- `flutter/build_android.sh` - Android build script
- `flutter/build_ios.sh` - iOS build script
- `flutter/build_fdroid.sh` - F-Droid build script
- `build.py` - Cross-platform build script with multiple options

### Custom Configuration Builds
- `CUSTOM_RENDEZVOUS_SERVER=your-server.com cargo build --release` - Build with custom rendezvous server
- `./build_custom.sh --key "key" --rendezvous "server.com"` - Build script with CLI args
- `python3 build_custom_config.py` - Generate custom config manually
- See `CUSTOM_CONFIG.md` for detailed documentation

### Docker Build
- `docker build -t "rustdesk-builder" .` - Build Docker container
- `docker run --rm -it -v $PWD:/home/user/rustdesk rustdesk-builder` - Build in Docker

## Project Architecture

### Core Structure
```
rustdesk/
├── src/                    # Main Rust application
│   ├── main.rs            # Entry point with platform-specific compilation
│   ├── lib.rs             # Core library module exports
│   ├── common.rs          # Shared utilities and global initialization
│   ├── client.rs          # Peer connection handling
│   ├── server/            # Audio/clipboard/input/video services
│   ├── platform/          # Platform-specific implementations
│   ├── ui/                # Legacy Sciter UI (deprecated)
│   ├── rendezvous_mediator.rs  # Rendezvous/relay server communication
│   └── flutter_ffi.rs     # Flutter-Rust bridge interface
├── flutter/               # Flutter UI (modern, cross-platform)
│   ├── lib/               # Flutter Dart code
│   │   ├── desktop/       # Desktop-specific UI
│   │   ├── mobile/        # Mobile-specific UI
│   │   ├── common/        # Shared UI components
│   │   └── models/        # State management and models
│   └── pubspec.yaml       # Flutter dependencies
├── libs/                  # Core Rust libraries
│   ├── hbb_common/        # Common utilities (codec, config, network, protobuf)
│   ├── scrap/             # Screen capture functionality
│   ├── enigo/             # Keyboard/mouse input simulation
│   ├── clipboard/         # Cross-platform clipboard
│   ├── virtual_display/   # Virtual display drivers (Windows)
│   └── remote_printer/    # Remote printing (Windows)
├── res/                   # Resources (icons, images)
└── build.py               # Cross-platform build script
```

### Key Components & Data Flow

#### 1. **Connection & Discovery**
- **`src/rendezvous_mediator.rs`** - Communicates with rustdesk-server for peer discovery
- **`src/lan.rs`** - LAN discovery via multicast
- **`src/client.rs`** - Initiates peer connections
- **`src/server/`** - Handles incoming connections

#### 2. **Screen Capture & Encoding**
- **`libs/scrap/`** - Platform-specific screen capture (DXGI, X11, Wayland, macOS)
- **`libs/hbb_common/src/video_codec.rs`** - Video encoding/decoding (VP8/VP9 via libvpx)
- **`libs/hbb_common/src/config.rs`** - Video quality and codec settings

#### 3. **Input Handling**
- **`libs/enigo/`** - Cross-platform keyboard/mouse simulation
- **`src/keyboard.rs`** - Keyboard event processing and mapping
- **`src/clipboard.rs`** - Clipboard synchronization

#### 4. **Audio Streaming**
- **`src/server/audio_service.rs`** - Audio capture and streaming
- **`libs/hbb_common/src/audio_codec.rs`** - Opus codec for audio

#### 5. **File Transfer**
- **`libs/hbb_common/src/fs.rs`** - File transfer protocol and utilities
- **`src/clipboard_file.rs`** - File copy/paste over clipboard

#### 6. **Flutter Bridge**
- **`src/flutter_ffi.rs`** - Flutter-Rust FFI interface
- **`src/flutter.rs`** - Flutter-specific functionality
- **`flutter/lib/`** - Dart code calling Rust via FFI

#### 7. **Custom Configuration System**
- **`build.rs`** - Build script that generates config from environment variables
- **`src/custom_config.rs`** - Generated at build time with embedded server settings
- **`src/custom_config::apply_build_config()`** - Applies configuration at startup
- **Integration points**: `core_main.rs`, `main.rs`, `flutter_ffi.rs`

### UI Architecture

#### Legacy UI (Deprecated)
- **`src/ui/`** - Sciter-based UI
- **`src/ui_interface.rs`** - UI state management
- **`src/ui_session_interface.rs`** - Session-specific UI logic

#### Modern UI (Flutter)
- **`flutter/lib/desktop/`** - Desktop-specific screens and widgets
- **`flutter/lib/mobile/`** - Mobile-specific screens and widgets
- **`flutter/lib/common/`** - Shared components (connection manager, settings)
- **`flutter/lib/models/`** - State management (Provider pattern)
- **`flutter/lib/bridge_generated.rs`** - Auto-generated FFI bindings

### Protocol Stack
1. **Discovery**: Rendezvous server or LAN multicast
2. **Connection**: TCP hole punching or relay via TURN
3. **Transport**: Custom protocol over TCP/UDP with encryption (NaCl)
4. **Media**: VP8/VP9 video + Opus audio + input events
5. **Control**: Session management, file transfer, clipboard sync

## Dependencies & Build Requirements

### Required System Dependencies
- **Rust toolchain** (1.75+)
- **C++ compiler** (GCC/Clang/MSVC)
- **vcpkg** for C++ libraries:
  - `libvpx` - VP8/VP9 video codec
  - `libyuv` - YUV color conversion
  - `opus` - Audio codec
  - `aom` - AV1 codec (optional)
- **Platform-specific**:
  - **Linux**: GTK3, X11/Wayland, GStreamer, PulseAudio/ALSA
  - **macOS**: Cocoa, CoreFoundation, ScreenCaptureKit
  - **Windows**: DirectX, WinAPI, virtual display drivers

### Optional Dependencies
- **Sciter** - Legacy UI (download separately)
- **Flutter** - Modern UI (3.1+)
- **Docker** - Containerized builds

### Environment Variables
- `VCPKG_ROOT` - Path to vcpkg installation
- `FLUTTER_ROOT` - Path to Flutter SDK (optional)

### Rust Features
- **Default**: `use_dasp` - Audio processing
- **UI**: `flutter` - Enable Flutter UI, `cli` - CLI mode
- **Media**: `hwcodec` - Hardware encoding, `vram` - VRAM optimization
- **Platform**: `unix-file-copy-paste`, `screencapturekit`, `linux-pkg-config`

## Configuration & Data

### Configuration Files
- **`libs/hbb_common/src/config.rs`** - Main configuration structure
  - `Settings` - User preferences (quality, audio, input)
  - `Local` - Local device settings
  - `Display` - Display configuration
  - `Built-in` - Default/readonly settings
- **`src/custom_config.rs`** - Build-time injected configuration (generated)
  - `CUSTOM_CLIENT_KEY` - Client authentication key
  - `CUSTOM_API_SERVER` - API server URL
  - `CUSTOM_RELAY_SERVER` - Relay server URL
  - `CUSTOM_RENDEZVOUS_SERVER` - Rendezvous server hostname

### Build-Time Configuration
The custom configuration system allows embedding server settings at build time:
```bash
# Environment variables are read by build.rs
export CUSTOM_RENDEZVOUS_SERVER="your-server.com"
export CUSTOM_CLIENT_KEY="your-key"

# Generated file is compiled into binary
cargo build --release

# Configuration is applied at startup
# See CUSTOM_CONFIG.md for full documentation
```

### Data Storage
- **Config**: Platform-specific config directories
- **Logs**: FlexiLogger with async support
- **Cache**: Temporary files, connection history

## Testing & Debugging

### Unit Tests
- `cargo test` - All Rust tests
- `cargo test -p hbb_common` - Test specific crate
- `cd flutter && flutter test` - Flutter tests

### Debug Builds
- `cargo run` - Debug build with logging
- `RUST_LOG=debug cargo run` - Enable debug logging
- `cargo run -- --help` - CLI options

### Platform-Specific Notes
- **Windows**: May require running as administrator for input simulation
- **Linux**: May require X11 permissions or Wayland portal access
- **macOS**: Requires screen recording and accessibility permissions

## Common Development Tasks

### Adding New Features
1. **Core functionality**: Add to appropriate `src/` module
2. **UI changes**: Update Flutter code in `flutter/lib/`
3. **Bridge updates**: Modify `src/flutter_ffi.rs` and regenerate bindings
4. **Configuration**: Update `libs/hbb_common/src/config.rs`

### Updating Dependencies
- **Rust**: Update `Cargo.toml` and run `cargo update`
- **Flutter**: Update `flutter/pubspec.yaml` and run `flutter pub get`
- **vcpkg**: Update packages with `vcpkg update`

### Cross-Platform Development
- Use `cfg_if` and platform-specific `#[cfg(target_os = "...")]`
- Test on all target platforms before merging
- Consider performance implications on low-end devices

## Important Files to Reference

- **`src/lib.rs`** - Core library exports and module structure
- **`src/common.rs`** - Global initialization and shared utilities
- **`src/rendezvous_mediator.rs`** - Connection establishment logic
- **`libs/hbb_common/src/config.rs`** - Configuration schema
- **`flutter/lib/models/`** - State management patterns
- **`build.py`** - Build configuration and options

## Ignore Patterns
- `target/` - Rust build artifacts
- `flutter/build/` - Flutter build output
- `flutter/.dart_tool/` - Flutter tooling
- `**/*.rs.bk` - Rust backup files
- `**/.DS_Store` - macOS metadata
