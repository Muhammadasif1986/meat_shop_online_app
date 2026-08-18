#!/bin/bash
# AGMS Flutter Mobile App - Setup & Build Script
# Run this on a machine with Flutter SDK installed

set -e

echo "========================================"
echo "AGMS Mobile App Setup"
echo "========================================"

# Check prerequisites
echo ""
echo "[1/5] Checking prerequisites..."

if ! command -v flutter &> /dev/null; then
    echo "ERROR: Flutter SDK not found."
    echo "Install Flutter from: https://docs.flutter.dev/get-started/install"
    echo ""
    echo "Quick install (Linux):"
    echo "  cd ~ && git clone https://github.com/flutter/flutter.git -b stable"
    echo '  export PATH="$PATH:$HOME/flutter/bin"'
    exit 1
fi

echo "  Flutter: $(flutter --version | head -1)"
echo "  Dart:    $(dart --version 2>&1)"

if ! command -v java &> /dev/null; then
    echo "WARNING: Java not found. Install JDK 17 for Android builds."
else
    echo "  Java:   $(java -version 2>&1 | head -1)"
fi

# Get dependencies
echo ""
echo "[2/5] Installing dependencies..."
flutter pub get

# Generate code (if using retrofit/json_serializable)
echo ""
echo "[3/5] Running code generation..."
flutter pub run build_runner build --delete-conflicting-outputs 2>/dev/null || echo "  (optional) No code generation needed"

# Analyze
echo ""
echo "[4/5] Running static analysis..."
flutter analyze

# Test
echo ""
echo "[5/5] Running tests..."
flutter test

echo ""
echo "========================================"
if [ $? -eq 0 ]; then
    echo "✓ Setup complete! Ready to build."
    echo ""
    echo "Build APK:    flutter build apk --debug"
    echo "Run device:   flutter run"
    echo "Run web:      flutter run -d chrome"
else
    echo "✗ Some checks failed. Review errors above."
fi
echo "========================================"
