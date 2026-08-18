#!/bin/bash
# Flutter SDK Installation Script
# Run this on your local machine (not in this environment)
set -e

FLUTTER_VERSION="3.22.2"
INSTALL_DIR="${HOME}/flutter"

echo "=== Installing Flutter SDK ${FLUTTER_VERSION} ==="

# Detect OS
OS="linux"
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    echo "On Windows? Use: https://docs.flutter.dev/get-started/install/windows"
    exit 1
fi

DOWNLOAD_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/${OS}/flutter_${OS}_${FLUTTER_VERSION}-stable.tar.xz"

echo "Downloading Flutter from:"
echo "  ${DOWNLOAD_URL}"

# Download (with resume support)
if command -v wget &> /dev/null; then
    wget -c --show-progress "${DOWNLOAD_URL}" -O /tmp/flutter.tar.xz
elif command -v curl &> /dev/null; then
    curl -C - -L --progress-bar "${DOWNLOAD_URL}" -o /tmp/flutter.tar.xz
fi

echo "Extracting..."
mkdir -p "${INSTALL_DIR}"
tar xf /tmp/flutter.tar.xz -C "${INSTALL_DIR}" --strip-components=1

echo "Adding to PATH..."
if [[ ":$PATH:" != *":${INSTALL_DIR}/bin:"* ]]; then
    echo "export PATH=\"${INSTALL_DIR}/bin:\$PATH\"" >> ~/.bashrc
    echo "export PATH=\"${INSTALL_DIR}/bin:\$PATH\"" >> ~/.profile
fi

export PATH="${INSTALL_DIR}/bin:${PATH}"

echo "Running flutter doctor..."
flutter doctor

echo ""
echo "=== Flutter ${FLUTTER_VERSION} installed! ==="
echo "Run 'source ~/.bashrc' or restart your terminal"
echo "Then 'cd mobile && flutter pub get && flutter run'"
