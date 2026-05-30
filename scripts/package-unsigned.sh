#!/bin/bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_PATH="$PROJECT_ROOT/SevenZipExtractor.xcodeproj"
SCHEME="SevenZipExtractor"
BUILD_ROOT="$PROJECT_ROOT/build"
ARCHIVE_ROOT="$BUILD_ROOT/release"
APP_PATH="$ARCHIVE_ROOT/$SCHEME.app"
ZIP_PATH="$BUILD_ROOT/${SCHEME}-unsigned-macos.zip"

rm -rf "$ARCHIVE_ROOT"
rm -f "$ZIP_PATH"
mkdir -p "$BUILD_ROOT"

xcodebuild build \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination "platform=macOS" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CONFIGURATION_BUILD_DIR="$ARCHIVE_ROOT"

if [ ! -d "$APP_PATH" ]; then
  echo "Expected app not found at $APP_PATH" >&2
  exit 1
fi

/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"

if [ ! -f "$ZIP_PATH" ]; then
  echo "Expected zip not found at $ZIP_PATH" >&2
  exit 1
fi

unzip -l "$ZIP_PATH" >/dev/null

echo "Built app: $APP_PATH"
echo "Packaged zip: $ZIP_PATH"
