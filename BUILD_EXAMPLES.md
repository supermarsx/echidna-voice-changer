# Echidna Build Examples

This document provides practical examples of building the Echidna voice changer project.

## Quick Start

### Basic Build (All ABIs)
```bash
# Build release version for all supported ABIs
./build-native.sh --all --release

# Build with tests
./build-native.sh --all --test

# Build with documentation
./build-native.sh --all --docs
```

### Specific ABI Build
```bash
# Build for ARM64 only
./build-native.sh -a arm64-v8a --release

# Build for ARMv7 with debug symbols
./build-native.sh -a armeabi-v7a --debug

# Build for x86_64 (emulator)
./build-native.sh -a x86_64 --release
```

## Development Builds

### Local Development
```bash
# Build with all quality checks
./build-native.sh --all --test --quality-checks --verbose

# Clean rebuild
./build-native.sh --all --clean --test

# Build with profiling enabled
./build-native.sh --all --profile --test
```

### CI/CD Build
```bash
# CI mode (minimal output, enhanced logging)
./build-native.sh --all --test --ci-mode --package

# Docker build for CI
./build-native.sh --all --use-docker --ci-mode
```

## Advanced Options

### Custom NDK Path
```bash
# Set custom NDK location
export ANDROID_NDK=/opt/android-ndk-r25c
./build-native.sh --all --release

# Or pass as argument
./build-native.sh --android-ndk /opt/android-ndk-r25c --all --release
```

### Parallel Builds
```bash
# Use 8 parallel jobs
./build-native.sh --all -j 8

# Use all available cores
./build-native.sh --all -j
```

### Custom Version
```bash
# Build specific version
./build-native.sh --all --version 1.0.0 --package

# Using environment variable
export ECHIDNA_VERSION=1.0.0
./build-native.sh --all --package
```

## Docker Builds

### Build with Docker
```bash
# Build using Docker container
./build-native.sh --all --use-docker

# Manual Docker build
docker build -f docker/Dockerfile -t echidna-builder .
docker run --rm -v $(pwd):/workspace echidna-builder ./build-native.sh --all
```

### Docker Compose
```bash
# Using docker-compose
docker-compose run --rm echidna-builder

# Development mode
docker-compose --profile dev run --rm echidna-dev
```

## Quality Assurance

### Code Quality
```bash
# Run all quality checks
./tools/code-quality.sh --auto-fix

# Only formatting
./tools/code-quality.sh --only-format

# Static analysis only
./build-native.sh --analyze
```

### Testing
```bash
# Unit tests only
./tests/run_tests.sh --unit

# Integration tests
./tests/run_tests.sh --integration

# Full test suite with coverage
./tests/run_tests.sh --all --coverage
```

## Deployment

### Package Creation
```bash
# Create release packages
./build-native.sh --all --package --version 1.0.0

# Create and sign packages
./build-native.sh --all --package --version 1.0.0 --sign

# Create deployment packages
./build-native.sh --all --deploy --version 1.0.0
```

### Magisk Module
```bash
# Create Magisk module package
./deployment/magisk-module.sh --version 1.0.0

# Multi-ABI module
./deployment/magisk-module.sh --multi-abi --version 1.0.0
```

## Troubleshooting

### Build Failures
```bash
# Verbose output to see what's failing
./build-native.sh --all --verbose

# Dry run to check configuration
./build-native.sh --all --dry-run

# Check specific ABI
./build-native.sh -a arm64-v8a --verbose
```

### Environment Issues
```bash
# Check prerequisites
./build-native.sh --help

# Install dependencies automatically
./build-native.sh --all --install-deps

# Setup ccache for faster builds
./build-native.sh --all --setup-ccache
```

### Log Analysis
```bash
# Check build logs
tail -f build/build.log
tail -f build/ci-build.log  # CI mode

# Search for errors
grep -i error build/build.log
grep -i warning build/build.log
```

## Performance Optimization

### Build Speed
```bash
# Enable ccache
./build-native.sh --all --setup-ccache

# Use more parallel jobs
./build-native.sh --all -j $(nproc)

# Docker builds (isolated, reproducible)
./build-native.sh --all --use-docker
```

### Resource Usage
```bash
# Check system resources before build
./build-native.sh --all --dry-run

# Limit memory usage (for low-end systems)
./build-native.sh --all -j 2
```

## Examples by Use Case

### Feature Development
```bash
# Quick iteration
./build-native.sh -a arm64-v8a --debug --test

# Full validation before commit
./build-native.sh --all --test --quality-checks --analyze
```

### Release Preparation
```bash
# Complete release build
./build-native.sh --all --release --test --docs --quality-checks --package --version 1.0.0

# With security signing
./build-native.sh --all --release --test --docs --quality-checks --package --version 1.0.0 --sign
```

### Continuous Integration
```bash
# Standard CI build
./build-native.sh --all --test --ci-mode --package

# Security-focused CI
./build-native.sh --all --test --quality-checks --analyze --ci-mode
```

### Debugging
```bash
# Debug build with symbols
./build-native.sh --all --debug --verbose

# Profile build
./build-native.sh --all --debug --profile --test
```

## Environment Variables

```bash
# Essential variables
export ANDROID_NDK=/path/to/ndk
export ECHIDNA_VERSION=1.0.0

# Optional variables
export ECHIDNA_SKIP_DEPS=0
export ECHIDNA_NO_COLOR=0
export CCACHE_DIR=/path/to/ccache
```

## File Structure After Build

```
build/
├── arm64-v8a/
│   └── lib/
│       └── arm64-v8a/
│           ├── libechidna.so
│           └── libech_dsp.so
├── armeabi-v7a/
│   └── lib/
│       └── armeabi-v7a/
│           ├── libechidna.so
│           └── libech_dsp.so
├── x86_64/
│   └── lib/
│       └── x86_64/
│           ├── libechidna.so
│           └── libech_dsp.so
├── packages/
│   ├── echidna-dev-Linux-x86_64.tar.gz
│   └── echidna-dev-Linux-x86_64.zip
└── docs/
    └── html/
        └── index.html
```

This covers the most common build scenarios for the Echidna project. For additional options, run `./build-native.sh --help`.