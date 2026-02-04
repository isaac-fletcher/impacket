#!/bin/bash

set -euo pipefail

### This script builds Linux static binaries from impacket example scripts
### Creates a temporary virtual environment and builds from examples/

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
python3 -m venv venv
source venv/bin/activate

# Install impacket and pyinstaller
echo "Installing impacket from ${REPO_DIR}..."
pip install --upgrade pip
pip install "${REPO_DIR}"
pip install pyinstaller

# Check pyinstaller is available
if ! command -v pyinstaller &> /dev/null; then
    echo "Error: pyinstaller not found after installation"
    exit 1
fi

# Create output directory
mkdir -p "${OUTPUT_DIR}"
ARCH=$(uname -m)

# Create standalone executables
for script in "${SCRIPTS_DIR}"/*.py; do
    name=$(basename "$script" .py)

    echo "Building ${name}..."

    # Clean previous build artifacts
    rm -rf build dist *.spec

    # Build with LD_LIBRARY_PATH preserved for pyinstaller
    if LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-}" pyinstaller --clean -F "$script"; then
        # Move and rename binary
        if [[ -f "dist/${name}" ]]; then
            mv "dist/${name}" "${OUTPUT_DIR}/${name}_linux_${ARCH}"
            echo "  -> ${OUTPUT_DIR}/${name}_linux_${ARCH}"
        fi
    else
        echo "  -> FAILED to build ${name}"
    fi
done

# Cleanup
cd /
rm -rf "${BUILDDIR}"

echo ""
echo "Build complete. Binaries are in ${OUTPUT_DIR}"
