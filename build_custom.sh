#!/bin/bash
#
# Custom RustDesk Build Script
# Supports CI/CD injection of custom server configuration
#
# Usage:
#   ./build_custom.sh --key <key> --rendezvous <server> [options]
#   CUSTOM_CLIENT_KEY=xxx CUSTOM_RENDEZVOUS_SERVER=xxx ./build_custom.sh
#   ./build_custom.sh --env-file .env.custom

set -e

# Default values
KEY=""
API_SERVER=""
RELAY_SERVER=""
RENDZVOUS_SERVER=""
ENV_FILE=""
BUILD_TYPE="release"
PLATFORM="auto"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --key)
            KEY="$2"
            shift 2
            ;;
        --api-server)
            API_SERVER="$2"
            shift 2
            ;;
        --relay-server)
            RELAY_SERVER="$2"
            shift 2
            ;;
        --rendezvous-server|--rendezvous)
            RENDEZVOUS_SERVER="$2"
            shift 2
            ;;
        --env-file)
            ENV_FILE="$2"
            shift 2
            ;;
        --build-type)
            BUILD_TYPE="$2"
            shift 2
            ;;
        --platform)
            PLATFORM="$2"
            shift 2
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

show_help() {
    cat << EOF
Custom RustDesk Build Script

Usage:
    $0 [options]

Options:
    --key <key>                 Client authentication key
    --api-server <url>          API server URL (optional)
    --relay-server <url>        Relay server URL (optional)
    --rendezvous-server <host>  Rendezvous server hostname (required)
    --env-file <path>           Load configuration from .env file
    --build-type <type>         Build type: debug, release (default: release)
    --platform <platform>       Target platform: linux, windows, macos, auto (default: auto)
    --help                      Show this help message

Environment Variables:
    CUSTOM_CLIENT_KEY           Client authentication key
    CUSTOM_API_SERVER           API server URL
    CUSTOM_RELAY_SERVER         Relay server URL
    CUSTOM_RENDEZVOUS_SERVER    Rendezvous server hostname

Examples:
    # Using command line arguments
    $0 --key "my-key" --rendezvous "server.example.com"

    # Using environment variables
    export CUSTOM_CLIENT_KEY="my-key"
    export CUSTOM_RENDEZVOUS_SERVER="server.example.com"
    $0

    # Using .env file
    $0 --env-file .env.custom

    # With additional servers
    $0 --key "my-key" --rendezvous "server.example.com" \
       --api-server "https://api.example.com" \
       --relay-server "https://relay.example.com"

EOF
}

# Load environment from file
load_env_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        log_info "Loading environment from: $file"
        set -a
        source "$file"
        set +a
    else
        log_error "Environment file not found: $file"
        exit 1
    fi
}

# Determine platform if auto
detect_platform() {
    if [[ "$PLATFORM" == "auto" ]]; then
        case "$(uname -s)" in
            Linux*)     PLATFORM="linux" ;;
            Darwin*)    PLATFORM="macos" ;;
            CYGWIN*|MINGW*|MSYS*) PLATFORM="windows" ;;
            *)          log_error "Unknown platform"; exit 1 ;;
        esac
    fi
    log_info "Target platform: $PLATFORM"
}

# Check required dependencies
check_dependencies() {
    log_info "Checking dependencies..."

    if ! command -v cargo &> /dev/null; then
        log_error "cargo not found. Please install Rust."
        exit 1
    fi

    if [[ "$PLATFORM" != "windows" ]] && ! command -v python3 &> /dev/null; then
        log_error "python3 not found."
        exit 1
    fi

    log_success "Dependencies OK"
}

# Generate custom configuration
generate_config() {
    log_info "Generating custom configuration..."

    # Use values from command line, then environment, then check if already set
    local key="${KEY:-$CUSTOM_CLIENT_KEY}"
    local api="${API_SERVER:-$CUSTOM_API_SERVER}"
    local relay="${RELAY_SERVER:-$CUSTOM_RELAY_SERVER}"
    local rendezvous="${RENDEZVOUS_SERVER:-$CUSTOM_RENDEZVOUS_SERVER}"

    # Validate required fields
    if [[ -z "$rendezvous" ]]; then
        log_error "Rendezvous server is required. Set --rendezvous-server or CUSTOM_RENDEZVOUS_SERVER"
        exit 1
    fi

    if [[ -z "$key" ]]; then
        log_warning "No client key provided. Using default configuration."
    fi

    # Generate configuration using Python script
    local cmd="python3 build_custom_config.py"
    cmd+=" --output src/custom_config.rs"
    cmd+=" --rendezvous-server \"$rendezvous\""

    if [[ -n "$key" ]]; then
        cmd+=" --key \"$key\""
    fi
    if [[ -n "$api" ]]; then
        cmd+=" --api-server \"$api\""
    fi
    if [[ -n "$relay" ]]; then
        cmd+=" --relay-server \"$relay\""
    fi

    if ! eval "$cmd"; then
        log_error "Failed to generate configuration"
        exit 1
    fi

    log_success "Configuration generated"
}

# Build the project
build_project() {
    local build_type="$1"
    local platform="$2"

    log_info "Building RustDesk ($build_type, $platform)..."

    # Set build features
    local features="flutter"

    # Set build command
    local build_cmd="cargo build"
    if [[ "$build_type" == "release" ]]; then
        build_cmd+=" --release"
    fi

    build_cmd+=" --features $features"

    # Set environment variables for build
    export CUSTOM_CLIENT_KEY="${KEY:-$CUSTOM_CLIENT_KEY}"
    export CUSTOM_API_SERVER="${API_SERVER:-$CUSTOM_API_SERVER}"
    export CUSTOM_RELAY_SERVER="${RELAY_SERVER:-$CUSTOM_RELAY_SERVER}"
    export CUSTOM_RENDEZVOUS_SERVER="${RENDEZVOUS_SERVER:-$CUSTOM_RENDEZVOUS_SERVER}"

    # Set vcpkg root if available
    if [[ -n "$VCPKG_ROOT" ]]; then
        export VCPKG_ROOT="$VCPKG_ROOT"
        log_info "Using vcpkg at: $VCPKG_ROOT"
    fi

    log_info "Running: $build_cmd"
    if ! $build_cmd; then
        log_error "Build failed"
        exit 1
    fi

    log_success "Build completed"
}

# Verify build output
verify_build() {
    local build_type="$1"
    local bin_dir="target/$build_type"

    log_info "Verifying build output..."

    if [[ "$PLATFORM" == "windows" ]]; then
        local binary="$bin_dir/rustdesk.exe"
    else
        local binary="$bin_dir/rustdesk"
    fi

    if [[ -f "$binary" ]]; then
        log_success "Binary created: $binary"

        # Show file info
        if [[ "$PLATFORM" != "windows" ]]; then
            ls -lh "$binary"
            file "$binary"
        else
            ls -lh "$binary"
        fi

        return 0
    else
        log_error "Binary not found: $binary"
        return 1
    fi
}

# Create package
create_package() {
    local build_type="$1"
    local rendezvous="${RENDEZVOUS_SERVER:-$CUSTOM_RENDEZVOUS_SERVER}"

    log_info "Creating package..."

    local package_dir="custom_build_${rendezvous}_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$package_dir"

    # Copy binary
    if [[ "$PLATFORM" == "windows" ]]; then
        cp "target/$build_type/rustdesk.exe" "$package_dir/"
        cp "target/$build_type/rustdesk.exe" "$package_dir/rustdesk-custom-${rendezvous}.exe"
    else
        cp "target/$build_type/rustdesk" "$package_dir/"
        cp "target/$build_type/rustdesk" "$package_dir/rustdesk-custom-${rendezvous}"
    fi

    # Create config file
    cat > "$package_dir/config.txt" << EOF
Custom RustDesk Configuration
=============================
Generated: $(date)
Platform: $PLATFORM
Build Type: $build_type

Server Configuration:
- Rendezvous: ${RENDEZVOUS_SERVER:-$CUSTOM_RENDEZVOUS_SERVER}
- API: ${API_SERVER:-$CUSTOM_API_SERVER:-default}
- Relay: ${RELAY_SERVER:-$CUSTOM_RELAY_SERVER:-default}
- Key: ${KEY:-$CUSTOM_CLIENT_KEY:+configured}

Usage:
  Run the executable to connect to your custom server.

Notes:
  - The client key is embedded in the binary
  - Server settings are configured at build time
  - Runtime configuration will override build settings if changed
EOF

    log_success "Package created: $package_dir"
    echo "$package_dir"
}

# Main execution
main() {
    log_info "Starting custom RustDesk build..."

    # Load env file if specified
    if [[ -n "$ENV_FILE" ]]; then
        load_env_file "$ENV_FILE"
    fi

    # Detect platform
    detect_platform

    # Check dependencies
    check_dependencies

    # Generate configuration
    generate_config

    # Build the project
    build_project "$BUILD_TYPE" "$PLATFORM"

    # Verify build
    if verify_build "$BUILD_TYPE"; then
        # Create package
        package_dir=$(create_package "$BUILD_TYPE")

        log_success "Build completed successfully!"
        log_info "Package: $package_dir"
        log_info "Binary: target/$BUILD_TYPE/rustdesk${PLATFORM == 'windows' && '.exe' || ''}"

        # Show summary
        echo ""
        echo "=== Build Summary ==="
        echo "Platform: $PLATFORM"
        echo "Build Type: $BUILD_TYPE"
        echo "Rendezvous Server: ${RENDEZVOUS_SERVER:-$CUSTOM_RENDEZVOUS_SERVER}"
        echo "API Server: ${API_SERVER:-$CUSTOM_API_SERVER:-default}"
        echo "Relay Server: ${RELAY_SERVER:-$CUSTOM_RELAY_SERVER:-default}"
        echo "Client Key: ${KEY:-$CUSTOM_CLIENT_KEY:+configured}"
        echo "===================="
    else
        log_error "Build verification failed"
        exit 1
    fi
}

# Run main function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi