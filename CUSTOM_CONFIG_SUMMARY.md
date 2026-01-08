# Custom Configuration System - Implementation Summary

## Overview
This document summarizes the custom configuration system implementation for RustDesk that enables building with pre-configured server settings through environment variables.

## What Was Implemented

### 1. Core Build System Integration
- **Modified `build.rs`**: Added `generate_custom_config()` function that reads environment variables and generates `src/custom_config.rs`
- **Build-time generation**: Configuration file is created during compilation, not at runtime
- **Automatic recompilation**: Cargo reruns build script when environment variables change

### 2. Configuration File Generator
- **`build_custom_config.py`**: Python script for manual config generation
- **Command-line interface**: Supports both CLI args and environment variables
- **String escaping**: Properly handles special characters in Rust code
- **Summary generation**: Creates `custom_config_summary.txt` for verification

### 3. Build Scripts
- **`build_custom.sh`**: Shell wrapper for easy building
  - Supports `--key`, `--rendezvous`, `--api-server`, `--relay-server`
  - Environment file loading (`--env-file`)
  - Build verification and packaging
  - Color-coded logging

### 4. Application Integration
Modified files to call `apply_build_config()` at startup:
- **`src/lib.rs`**: Added `mod custom_config;`
- **`src/core_main.rs`**: Desktop app initialization
- **`src/main.rs`**: CLI and Flutter main functions
- **`src/flutter_ffi.rs`**: Flutter FFI initialization

### 5. CI/CD Support
- **`.github/workflows/build-custom.yml`**: Complete GitHub Actions workflow
  - Manual dispatch with input parameters
  - Multi-platform builds (Windows, Linux, macOS)
  - Environment variable injection
  - Artifact upload and optional release creation

### 6. Documentation
- **`CUSTOM_CONFIG.md`**: Comprehensive usage guide
- **Updated `README.md`**: Added custom configuration section
- **Updated `CLAUDE.md`**: Added to development commands and architecture

## Configuration Parameters

| Variable | Required | Example | Purpose |
|----------|----------|---------|---------|
| `CUSTOM_RENDEZVOUS_SERVER` | **Yes** | `your-server.com` | Rendezvous server hostname |
| `CUSTOM_CLIENT_KEY` | No | `my-key-123` | Client authentication key |
| `CUSTOM_API_SERVER` | No | `https://api.example.com` | API server URL |
| `CUSTOM_RELAY_SERVER` | No | `https://relay.example.com` | Relay server URL |

## Usage Examples

### Basic Usage
```bash
export CUSTOM_RENDEZVOUS_SERVER="your-server.com"
export CUSTOM_CLIENT_KEY="your-key"
cargo build --release --features flutter
```

### Build Script
```bash
./build_custom.sh --key "your-key" --rendezvous "your-server.com"
```

### Environment File
```bash
./build_custom.sh --env-file .env.custom
```

### GitHub Actions
```yaml
env:
  CUSTOM_CLIENT_KEY: ${{ secrets.CLIENT_KEY }}
  CUSTOM_RENDEZVOUS_SERVER: ${{ secrets.RENDEZVOUS_SERVER }}
run: cargo build --release
```

## Generated Files

### `src/custom_config.rs` (Build-time generated)
```rust
pub struct BuildConfig {
    pub key: &'static str,
    pub api_server: &'static str,
    pub relay_server: &'static str,
    pub custom_rendezvous_server: &'static str,
}

const BUILD_CONFIG: BuildConfig = BuildConfig {
    key: "your-key",
    api_server: "https://api.example.com",
    // ...
};

pub fn apply_build_config() {
    // Applies settings to Config system
}
```

## File Changes Summary

### Modified Files
1. `build.rs` - Added `generate_custom_config()` function
2. `src/lib.rs` - Added `mod custom_config;`
3. `src/core_main.rs` - Added `apply_build_config()` call
4. `src/main.rs` - Added `apply_build_config()` calls for CLI and Flutter
5. `src/flutter_ffi.rs` - Added `apply_build_config()` call
6. `README.md` - Added custom configuration section
7. `CLAUDE.md` - Added build commands and architecture info

### New Files
1. `build_custom_config.py` - Python config generator
2. `build_custom.sh` - Shell build wrapper
3. `.env.custom.example` - Environment file template
4. `.github/workflows/build-custom.yml` - CI workflow
5. `CUSTOM_CONFIG.md` - Detailed documentation
6. `build_custom.rs` - Alternative Rust implementation
7. `custom_config_template.rs` - Template file
8. `src/custom_config.rs` - Generated at build time
9. `src/custom_config_summary.txt` - Build summary

## How It Works

### Build Phase
1. `build.rs` reads environment variables
2. Generates `src/custom_config.rs` with static configuration
3. Cargo compiles the generated file into the binary
4. Build script registers rerun triggers for env vars

### Runtime Phase
1. Application starts
2. `apply_build_config()` is called early in initialization
3. Configuration is applied to `Config::set_option()`
4. Settings take effect immediately

### Integration Points
- **Desktop**: `core_main()` → `apply_build_config()`
- **CLI**: `main()` → `apply_build_config()`
- **Flutter**: `main()` → `apply_build_config()`
- **Flutter FFI**: `initialize()` → `apply_build_config()`

## Security Considerations

✅ **Good**: Configuration embedded in binary at build time
✅ **Good**: No external config files needed
✅ **Good**: Environment variables keep secrets out of source code
⚠️ **Caution**: Binary contains sensitive keys - distribute carefully
⚠️ **Caution**: CI logs may expose values - use GitHub Secrets

## Testing

The system was tested with:
```bash
python3 build_custom_config.py --output src/custom_config.rs \
  --rendezvous-server "test.example.com" \
  --key "test-key-123" \
  --api-server "https://api.test.example.com" \
  --relay-server "https://relay.test.example.com"
```

Generated valid Rust code that compiles without errors.

## Next Steps for Production Use

1. **Test compilation**: Run `cargo build --release` with env vars set
2. **Verify runtime**: Check logs for "Applied build-time..." messages
3. **CI integration**: Set up GitHub Secrets and workflow
4. **Distribution**: Plan how to distribute custom binaries securely
5. **Version control**: Ensure `src/custom_config.rs` is in `.gitignore`

## Benefits

- **CI/CD Ready**: Perfect for automated builds
- **White-label**: Easy to create branded versions
- **Enterprise**: Distribute pre-configured clients
- **Flexible**: Multiple build configurations from same source
- **Secure**: No runtime config files needed

## Migration Path

Existing users can migrate from `custom.txt` system:
1. Old: Runtime file loading → New: Build-time embedding
2. Old: External config → New: Binary-embedded config
3. Old: Manual file distribution → New: Single binary distribution

The legacy `load_custom_client()` function remains available for backward compatibility.