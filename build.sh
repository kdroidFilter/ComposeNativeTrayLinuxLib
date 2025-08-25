#!/bin/bash

# Exit on any error
set -e

echo "Building Linux systray shared library..."

# Ensure we run from this script's directory (linuxlib)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Inform about architecture if provided
if [[ -n "$GOARCH" ]]; then
  echo "Using GOARCH=$GOARCH"
else
  echo "GOARCH not set, defaulting to amd64 (as per Makefile)"
fi

# Build the shared library using the provided Makefile target
make build-so

# Destination directory in the Kotlin resources
DEST_DIR="../src/commonMain/resources/linux-x86-64"
mkdir -p "$DEST_DIR"

# Copy the generated .so to the resources directory
cp -f dist/libsystray.so "$DEST_DIR/libsystray.so"

echo "Copied dist/libsystray.so to $DEST_DIR/libsystray.so"
echo "Linux build completed successfully."