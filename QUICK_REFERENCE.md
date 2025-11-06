# Echidna Build System Quick Reference

## Essential Commands

| Task | Command |
|------|---------|
| Build all | `./build-native.sh --all --release` |
| Build with tests | `./build-native.sh --all --test` |
| Run quality checks | `./tools/code-quality.sh` |
| Android build | `./tools/android/ndk-build-wrapper.sh --all-abis` |
| Device testing | `./tools/android/device-testing.sh --all` |
| Create release | `./deployment/magisk-module.sh --version 1.0.0` |

## Build Options

| Option | Description |
|--------|-------------|
| `--all` | Build all ABIs |
| `-a ABI` | Build specific ABI |
| `--test` | Build with tests |
| `--docs` | Generate documentation |
| `--clean` | Clean before building |
| `--verbose` | Verbose output |
| `--docker` | Use Docker build |

## Quality Checks

| Tool | Purpose | Key Options |
|------|---------|-------------|
| `code-quality.sh` | Code formatting & analysis | `--auto-fix`, `--only-format` |
| `ndk-build-wrapper.sh` | Android builds | `--all-abis`, `--package` |
| `device-testing.sh` | Device testing | `--test audio`, `--test magisk` |
| `apk-signing.sh` | APK signing | `--create-keystore`, `--sign` |
| `module-packaging.sh` | Module packaging | `package`, `multi-abi` |

## Docker Commands

| Action | Command |
|--------|---------|
| Build image | `docker build -f docker/Dockerfile -t echidna-builder .` |
| Run container | `docker run -it --rm -v $(pwd):/workspace echidna-builder` |
| Use Compose | `docker-compose run --rm echidna-builder` |
| Development mode | `docker-compose --profile dev run --rm echidna-dev` |

## Environment Variables

```bash
# Required
ANDROID_NDK=/path/to/ndk

# Optional
ECHIDNA_VERSION=1.0.0
ECHIDNA_SKIP_DEPS=0
ECHIDNA_NO_COLOR=0
```

## Common Issues

1. **Build fails**: Check NDK path, run with `--verbose`
2. **Tests fail**: Check device connection, review logs
3. **Quality fails**: Use `--auto-fix`, review reports
4. **Docker issues**: Check Docker installation, rebuild image

## File Locations

| Purpose | Location |
|---------|----------|
| Build output | `build/` |
| Test reports | `testing/reports/` |
| Quality reports | `reports/` |
| Security reports | `security-reports/` |
| Distribution | `release/` |
| Documentation | `docs/` |

## Get Help

- Full documentation: `docs/build-system-enhancements.md`
- Usage examples: `BUILD_EXAMPLES.md`
- Script help: `./script-name --help`