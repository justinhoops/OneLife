#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${ROOT}/Documentation/AppStoreScreenshots"
DESTINATION="${DESTINATION:-platform=iOS Simulator,name=iPhone 17}"

mkdir -p "$OUT"

cd "$ROOT"

xcodebuild \
  -scheme OneLife \
  -destination "$DESTINATION" \
  test \
  -only-testing:OneLifeUITests/testCaptureAppStoreScreenshotFrames

RESULT=$(ls -t "$HOME"/Library/Developer/Xcode/DerivedData/OneLife*/Logs/Test/*.xcresult 2>/dev/null | head -1)
if [[ -n "$RESULT" ]]; then
  EXPORT_DIR="$OUT/_xcresult_export"
  rm -rf "$EXPORT_DIR"
  xcrun xcresulttool export attachments --path "$RESULT" --output-path "$EXPORT_DIR" >/dev/null 2>&1 || true
  find "$EXPORT_DIR" -name '*.png' -exec cp {} "$OUT/" \; 2>/dev/null || true
  rm -rf "$EXPORT_DIR"
  echo "Xcode test report: $RESULT"
  echo "If PNGs are missing here, open the .xcresult in Xcode → Report navigator → testCaptureAppStoreScreenshotFrames → save frame attachments."
fi

echo "Screenshots written to: $OUT"
ls -1 "$OUT"/*.png 2>/dev/null || echo "(export attachments from latest xcresult if PNGs missing)"
