#!/usr/bin/env bash
# Build StagemanTool.app (Release, macOS) into ./build
set -euo pipefail

cd "$(dirname "$0")"

CONFIGURATION="${CONFIGURATION:-Release}"
BUILD_DIR="build"
DERIVED_DATA="$BUILD_DIR/DerivedData"

xcodebuild \
    -project StagemanTool.xcodeproj \
    -scheme StagemanTool \
    -configuration "$CONFIGURATION" \
    -destination 'platform=macOS' \
    -derivedDataPath "$DERIVED_DATA" \
    build

APP="$DERIVED_DATA/Build/Products/$CONFIGURATION/StagemanTool.app"
rm -rf "$BUILD_DIR/StagemanTool.app"
cp -R "$APP" "$BUILD_DIR/"

echo "Built: $BUILD_DIR/StagemanTool.app"
