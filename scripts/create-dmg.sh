#!/bin/bash
# Usage: ./scripts/create-dmg.sh [version]
# Example: ./scripts/create-dmg.sh 1.0.0

set -e

APP_NAME="Bartidy"
VERSION="${1:-1.0.0}"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
BUILD_DIR="build/Release"
OUTPUT_DIR="release"
TEMP_DIR=$(mktemp -d)

echo "🔨 Creating DMG for ${APP_NAME} v${VERSION}..."

if [ ! -d "${BUILD_DIR}/${APP_NAME}.app" ]; then
    echo "❌ Error: ${BUILD_DIR}/${APP_NAME}.app not found"
    echo "   Build the app first: xcodebuild -scheme Bartidy -configuration Release build"
    exit 1
fi

mkdir -p "${OUTPUT_DIR}"

echo "📦 Copying app bundle..."
cp -R "${BUILD_DIR}/${APP_NAME}.app" "${TEMP_DIR}/"

echo "💿 Creating DMG..."
hdiutil create -volname "${APP_NAME}" \
    -srcfolder "${TEMP_DIR}" \
    -ov \
    -format UDZO \
    "${OUTPUT_DIR}/${DMG_NAME}"

rm -rf "${TEMP_DIR}"

SHA256=$(shasum -a 256 "${OUTPUT_DIR}/${DMG_NAME}" | awk '{print $1}')

echo ""
echo "✅ DMG created: ${OUTPUT_DIR}/${DMG_NAME}"
echo ""
echo "📋 SHA256: ${SHA256}"
echo ""
echo "📝 Next steps:"
echo "   1. Upload ${OUTPUT_DIR}/${DMG_NAME} to GitHub Releases"
echo "   2. Update Casks/bartidy.rb:"
echo "      - version \"${VERSION}\""
echo "      - sha256 \"${SHA256}\""
echo ""
