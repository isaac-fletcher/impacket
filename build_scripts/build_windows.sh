#!/bin/bash

set -euo pipefail

### This script builds Windows executables from impacket example scripts
### Creates a temporary virtual environment and builds from examples/
### Designed to run on Windows (via Git Bash) or GitHub Actions windows-latest

# Configuration - detect repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="${REPO_DIR:-$(dirname "$SCRIPT_DIR")}"
SCRIPTS_DIR="${REPO_DIR}/examples"
OUTPUT_DIR="${OUTPUT_DIR:-${REPO_DIR}/dist}"

# Check that examples directory exists
if [[ ! -d "${SCRIPTS_DIR}" ]]; then
    echo "Error: examples directory not found at ${SCRIPTS_DIR}"
    exit 1
fi

# Change to temp directory for build
BUILDDIR=$(mktemp -d)
cd "${BUILDDIR}"

# Create and activate virtual environment
echo "Creating virtual environment..."
python -m venv venv

# Activate venv (Windows style if on Windows, otherwise bash style)
if [[ -f "venv/Scripts/activate" ]]; then
    source venv/Scripts/activate
else
    source venv/bin/activate
fi

# Install impacket and pyinstaller
echo "Installing impacket from ${REPO_DIR}..."
python -m pip install --upgrade pip
python -m pip install "${REPO_DIR}"
python -m pip install pyinstaller

# Check pyinstaller is available
if ! command -v pyinstaller &> /dev/null; then
    echo "Error: pyinstaller not found after installation"
    exit 1
fi

# Create output directory
mkdir -p "${OUTPUT_DIR}"

# Create standalone executables
for script in "${SCRIPTS_DIR}"/*.py; do
    name=$(basename "$script" .py)

    echo "Building ${name}..."

    # Clean previous build artifacts
    rm -rf build dist *.spec

    # Build with pyinstaller
    if pyinstaller --clean -F "$script"; then
        # Move and rename binary
        if [[ -f "dist/${name}.exe" ]]; then
            mv "dist/${name}.exe" "${OUTPUT_DIR}/${name}_windows.exe"
            echo "  -> ${OUTPUT_DIR}/${name}_windows.exe"
        elif [[ -f "dist/${name}" ]]; then
            mv "dist/${name}" "${OUTPUT_DIR}/${name}_windows"
            echo "  -> ${OUTPUT_DIR}/${name}_windows"
        fi
    else
        echo "  -> FAILED to build ${name}"
    fi
done

# Cleanup
cd /
rm -rf "${BUILDDIR}" 2>/dev/null || true

echo ""
echo "Build complete. Binaries are in ${OUTPUT_DIR}"
