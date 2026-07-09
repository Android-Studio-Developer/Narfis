#!/usr/bin/env bash
set -euo pipefail

DOWNLOAD_URL="https://github.com/Android-Studio-Developer/Narfis/releases/download/v0.1.0-pre1/Narfis.dmg"

if [[ "$(uname)" != "Darwin" ]]; then
  echo "narfis currently only supports macOS 13.5 and above."
  exit 1
fi

WORK_DIR="$(mktemp -d)"
DMG_PATH="$WORK_DIR/narfis.dmg"

echo "Downloading narfis..."
curl -fL -o "$DMG_PATH" "$DOWNLOAD_URL"

echo "Mounting disk image..."
MOUNT_DIR="$WORK_DIR/mount"
mkdir -p "$MOUNT_DIR"
hdiutil attach "$DMG_PATH" -nobrowse -mountpoint "$MOUNT_DIR" >/dev/null

APP_PATH="$(find "$MOUNT_DIR" -maxdepth 1 -name "*.app" -print -quit)"
if [[ -z "$APP_PATH" ]]; then
  echo "Could not find narfis.app inside the disk image."
  hdiutil detach "$MOUNT_DIR" >/dev/null
  rm -rf "$WORK_DIR"
  exit 1
fi

echo "Installing to /Applications..."
rm -rf "/Applications/$(basename "$APP_PATH")"
cp -R "$APP_PATH" /Applications/

hdiutil detach "$MOUNT_DIR" >/dev/null
rm -rf "$WORK_DIR"

echo "narfis installed. Launching..."
open "/Applications/$(basename "$APP_PATH")"
