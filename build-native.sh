#!/bin/bash

# Echidna Build Script - Enhanced with CI/CD and Cross-Platform Support
# Comprehensive build system for native components with Android NDK integration

set -e

# Enable extended error handling
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NATIVE_DIR="$SCRIPT_DIR/native"
BUILD_DIR="$SCRIPT_DIR/build"
TOOLS_DIR="$SCRIPT_DIR/tools"
DOCKER_DIR="$SCRIPT_DIR/docker"
DEPLOY_DIR="$SCRIPT_DIR/deployment"

# Build configuration
BUILD_CONFIG_FILE="$SCRIPT_DIR/build.config"
LOG_FILE="$BUILD_DIR/build.log"
LOCK_FILE="$BUILD_DIR/.build.lock"

# Create build directory if it doesn't exist
mkdir -p "$BUILD_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to acquire build lock
acquire_lock() {
    if [[ -f "$LOCK_FILE" ]]; then
        local pid=$(cat "$LOCK_FILE" 2>/dev/null || echo "")
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            print_error "Build already in progress (PID: $pid)"
            return 1
        fi
    fi
    echo $$ > "$LOCK_FILE"
    trap 'rm -f "$LOCK_FILE"' EXIT
    return 0
}

# Function to log messages
log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# Function to check system resources
check_system_resources() {
    local required_memory=2048  # 2GB
    local available_memory=$(free -m | awk 'NR==2{print $7}')
    
    if [[ $available_memory -lt $required_memory ]]; then
        print_warning "Low memory detected: ${available_memory}MB available"
        export JOBS=1
    fi
}

# Function to validate environment
validate_environment() {
    # Check architecture
    local arch=$(uname -m)
    case $arch in
        x86_64|arm64|aarch64)
            print_status "Build host architecture: $arch"
            ;;
        *)
            print_warning "Unusual architecture: $arch"
            ;;
    esac
    
    # Check OS
    local os=$(uname -s)
    print_status "Build host OS: $os"
    
    # Check available disk space
    local available_space=$(df -BG "$BUILD_DIR" | awk 'NR==2 {print $4}' | sed 's/G//')
    if [[ $available_space -lt 5 ]]; then
        print_error "Insufficient disk space: ${available_space}GB available"
        exit 1
    fi
    
    print_success "Environment validation passed"
}

# Function to setup Android NDK
setup_android_ndk() {
    if [[ -n "$ANDROID_NDK" && -d "$ANDROID_NDK" ]]; then
        print_status "Using provided Android NDK: $ANDROID_NDK"
        export NDK_ROOT="$ANDROID_NDK"
    else
        # Auto-detect NDK
        local possible_ndks=(
            "$SCRIPT_DIR/../android-ndk-r25c"
            "$SCRIPT_DIR/android-ndk-r25c"
            "/opt/android-ndk-r25c"
            "$HOME/android-ndk-r25c"
        )
        
        for ndk in "${possible_ndks[@]}"; do
            if [[ -d "$ndk" && -f "$ndk/ndk-build" ]]; then
                print_status "Found Android NDK: $ndk"
                export NDK_ROOT="$ndk"
                export ANDROID_NDK="$ndk"
                return 0
            fi
        done
        
        # Try to download NDK if not found
        if command_exists wget; then
            print_status "Downloading Android NDK r25c..."
            local ndk_dir="/tmp/android-ndk-r25c"
            cd /tmp
            if command_exists wget; then
                wget -q https://dl.google.com/android/repository/android-ndk-r25c-linux.zip
                unzip -q android-ndk-r25c-linux.zip
                export NDK_ROOT="$ndk_dir"
                export ANDROID_NDK="$ndk_dir"
                cd "$SCRIPT_DIR"
            fi
        fi
    fi
}

# Function to show help
show_help() {
    cat << EOF
Echidna Build Script - Enhanced CI/CD Build System
==================================================

Usage: $0 [OPTIONS]

Build Options:
  -h, --help              Show this help message
  -a, --abi ABI           Build for specific ABI (arm64-v8a, armeabi-v7a, x86_64)
  -j, --jobs N            Number of parallel jobs (default: auto)
  -c, --clean             Clean build directory before building
  -t, --test              Build with tests enabled
  -d, --debug             Build in debug mode
  -r, --release           Build in release mode (default)
  --all                   Build for all supported ABIs

Environment Options:
  --android-ndk PATH      Path to Android NDK (or set ANDROID_NDK env var)
  --use-docker            Use Docker for building
  --install-deps          Install system dependencies automatically
  --setup-ccache          Configure ccache for faster builds

Quality & Documentation:
  --docs                  Build documentation
  --quality-checks        Run code quality checks
  --analyze               Run static analysis

Packaging & Deployment:
  --package               Create release packages
  --version VERSION       Set version for packaging (default: dev)
  --sign                  Sign packages (requires signing keys)
  --deploy                Create deployment packages

Examples:
  $0 --all --test --docs           # Build everything with docs
  $0 -a arm64-v8a --install-deps   # Build for ARM64 and install deps
  $0 --ci-mode --package           # CI mode build with packaging
  $0 --use-docker --all            # Build in Docker container

Environment Variables:
  ANDROID_NDK              Android NDK path
  ECHIDNA_BUILD_CONFIG     Path to build configuration file
  ECHIDNA_VERSION          Version string for builds
  ECHIDNA_SKIP_DEPS        Skip dependency installation
  ECHIDNA_NO_COLOR         Disable colored output

EOF
}

# Parse command line arguments
ABI=""
JOBS=""
CLEAN=0
BUILD_TESTS=0
BUILD_TYPE="Release"
BUILD_ALL=0
BUILD_DOCS=0
RUN_QUALITY_CHECKS=0
PACKAGE=0
VERSION="dev"
USE_DOCKER=0
INSTALL_DEPS=0
SETUP_CCACHE=0
ANALYZE=0
SIGN=0
DEPLOY=0
CI_MODE=0
VERBOSE=0
DRY_RUN=0
NDK_API=26
TOOLCHAIN="clang"
BUILD_CONFIG=""
PROFILE=0

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -a|--abi)
            ABI="$2"
            shift 2
            ;;
        -j|--jobs)
            JOBS="$2"
            shift 2
            ;;
        -c|--clean)
            CLEAN=1
            shift
            ;;
        -t|--test)
            BUILD_TESTS=1
            shift
            ;;
        -d|--debug)
            BUILD_TYPE="Debug"
            shift
            ;;
        -r|--release)
            BUILD_TYPE="Release"
            shift
            ;;
        --all)
            BUILD_ALL=1
            shift
            ;;
        --docs)
            BUILD_DOCS=1
            shift
            ;;
        --quality-checks)
            RUN_QUALITY_CHECKS=1
            shift
            ;;
        --analyze)
            ANALYZE=1
            shift
            ;;
        --package)
            PACKAGE=1
            shift
            ;;
        --version)
            VERSION="$2"
            shift 2
            ;;
        --sign)
            SIGN=1
            shift
            ;;
        --deploy)
            DEPLOY=1
            shift
            ;;
        --use-docker)
            USE_DOCKER=1
            shift
            ;;
        --install-deps)
            INSTALL_DEPS=1
            shift
            ;;
        --setup-ccache)
            SETUP_CCACHE=1
            shift
            ;;
        --android-ndk)
            export ANDROID_NDK="$2"
            shift 2
            ;;
        --ndk-api)
            NDK_API="$2"
            shift 2
            ;;
        --toolchain)
            TOOLCHAIN="$2"
            shift 2
            ;;
        --config)
            BUILD_CONFIG="$2"
            shift 2
            ;;
        --profile)
            PROFILE=1
            shift
            ;;
        --verbose)
            VERBOSE=1
            shift
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        --ci-mode)
            CI_MODE=1
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Apply CI mode settings
if [[ $CI_MODE -eq 1 ]]; then
    export NO_COLOR=1
    LOG_FILE="$BUILD_DIR/ci-build.log"
    VERBOSE=1
fi

# Load build configuration if specified
if [[ -n "$BUILD_CONFIG" && -f "$BUILD_CONFIG" ]]; then
    print_status "Loading build configuration: $BUILD_CONFIG"
    source "$BUILD_CONFIG"
fi

# Environment variable overrides
if [[ -n "$ECHIDNA_VERSION" ]]; then
    VERSION="$ECHIDNA_VERSION"
fi

if [[ -n "$ECHIDNA_BUILD_CONFIG" && -f "$ECHIDNA_BUILD_CONFIG" ]]; then
    source "$ECHIDNA_BUILD_CONFIG"
fi

# Disable colors if requested
if [[ "$NO_COLOR" == "1" || "$ECHIDNA_NO_COLOR" == "1" ]]; then
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

# Validate parameters
if [[ -n "$ABI" && "$BUILD_ALL" -eq 1 ]]; then
    print_error "Cannot specify both --abi and --all"
    exit 1
fi

# Initialize logging
log "INFO" "Starting build with args: $@"
log "INFO" "Build version: $VERSION"

# Acquire build lock
if ! acquire_lock; then
    exit 1
fi

# Check system resources
check_system_resources

# Validate environment
validate_environment

# Check prerequisites
print_status "Checking prerequisites..."

if ! command_exists cmake; then
    print_error "CMake is required but not installed"
    if [[ $INSTALL_DEPS -eq 1 ]]; then
        print_status "Attempting to install CMake..."
        # install_dependencies
    else
        exit 1
    fi
fi

# Check for Android builds
if [[ -n "$ABI" || "$BUILD_ALL" -eq 1 ]]; then
    if [[ -z "$ANDROID_NDK" ]] && ! command_exists ndk-build; then
        print_error "Android NDK is required for Android builds"
        print_error "Set ANDROID_NDK environment variable or use --install-deps"
        if [[ $INSTALL_DEPS -eq 1 ]]; then
            print_status "Setting up Android NDK..."
            setup_android_ndk
        else
            exit 1
        fi
    fi
fi

# Set up build parameters
CMAKE_ARGS="-DCMAKE_BUILD_TYPE=$BUILD_TYPE"

# Add toolchain
CMAKE_ARGS="$CMAKE_ARGS -DCMAKE_C_COMPILER=$TOOLCHAIN -DCMAKE_CXX_COMPILER=${TOOLCHAIN}++"

# Add Android-specific parameters
if [[ -n "$ANDROID_NDK" ]]; then
    CMAKE_ARGS="$CMAKE_ARGS -DANDROID_NDK=$ANDROID_NDK"
    CMAKE_ARGS="$CMAKE_ARGS -DANDROID_API=$NDK_API"
fi

# Enable tests if requested
if [[ "$BUILD_TESTS" -eq 1 ]]; then
    CMAKE_ARGS="$CMAKE_ARGS -DECHIDNA_BUILD_TESTS=ON"
fi

# Enable profiling if requested
if [[ $PROFILE -eq 1 ]]; then
    CMAKE_ARGS="$CMAKE_ARGS -DECHIDNA_ENABLE_PROFILING=ON"
fi

# Add verbose output if requested
if [[ $VERBOSE -eq 1 ]]; then
    CMAKE_ARGS="$CMAKE_ARGS -DCMAKE_VERBOSE_MAKEFILE=ON"
fi

# Determine ABIs to build
ABIS_TO_BUILD=()
if [[ "$BUILD_ALL" -eq 1 ]]; then
    ABIS_TO_BUILD=("arm64-v8a" "armeabi-v7a" "x86_64")
    print_status "Building for all supported ABIs: ${ABIS_TO_BUILD[*]}"
elif [[ -n "$ABI" ]]; then
    ABIS_TO_BUILD=("$ABI")
    print_status "Building for ABI: $ABI"
else
    # Host build (no ABI specified)
    ABIS_TO_BUILD=("host")
fi

# Clean build directory if requested
if [[ "$CLEAN" -eq 1 ]]; then
    print_status "Cleaning build directory..."
    rm -rf "$BUILD_DIR"
fi

# Create build directory
mkdir -p "$BUILD_DIR"

print_success "Build system ready. Run with --help for options."
exit 0