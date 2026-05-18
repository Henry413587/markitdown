#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPOSITORY_ROOT="$(cd "$ROOT_DIR/../.." && pwd)"
APP_NAME="MarkitdownMac"
PRODUCT_PATH="$ROOT_DIR/.build/debug/$APP_NAME"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
MACOS_DIR="$APP_BUNDLE/Contents/MacOS"
RESOURCES_DIR="$APP_BUNDLE/Contents/Resources"
RUNTIME_DIR="$ROOT_DIR/build/python-runtime"
ICON_FILE="$ROOT_DIR/Resources/AppIcon.icns"
BUILD_PYTHON_RUNTIME=0
COMMAND="${1:-}"

if [ "$COMMAND" = "--with-python" ]; then
  BUILD_PYTHON_RUNTIME=1
  shift
  COMMAND="${1:-}"
fi

cd "$ROOT_DIR"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

if [ "$BUILD_PYTHON_RUNTIME" -eq 1 ]; then
  ./script/build_python_runtime.sh
fi

swift build

rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp "$PRODUCT_PATH" "$MACOS_DIR/$APP_NAME"

if [ -f "$ICON_FILE" ]; then
  cp "$ICON_FILE" "$RESOURCES_DIR/AppIcon.icns"
fi

if [ -d "$RUNTIME_DIR" ]; then
  cp -R "$RUNTIME_DIR" "$RESOURCES_DIR/Python"
fi

cat > "$APP_BUNDLE/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>local.markitdown.mac</string>
  <key>CFBundleName</key>
  <string>MarkItDown</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>15.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
  <key>LSEnvironment</key>
  <dict>
    <key>MARKITDOWN_REPOSITORY_ROOT</key>
    <string>$REPOSITORY_ROOT</string>
  </dict>
</dict>
</plist>
PLIST

case "$COMMAND" in
  --verify)
    /usr/bin/open -n "$APP_BUNDLE"
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    echo "$APP_NAME is running."
    ;;
  --logs)
    /usr/bin/open -n "$APP_BUNDLE"
    /usr/bin/log stream --style compact --predicate "process == '$APP_NAME'"
    ;;
  *)
    /usr/bin/open -n "$APP_BUNDLE"
    ;;
esac
