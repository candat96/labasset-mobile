#!/usr/bin/env bash
# Dựng IPA MedOne rồi nạp lên TestFlight bằng mật khẩu riêng cho ứng dụng.
#
#   tool/testflight.sh            # build + upload
#   tool/testflight.sh --no-upload
#
# Yêu cầu trong .env.release: APPLE_ID, APPLE_TEAM_ID, APPLE_APP_SPECIFIC_PASSWORD.
# Máy phải đã đăng nhập Xcode với tài khoản có quyền ký cho com.labasset.app.
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT=$(pwd)

[ -f .env.release ] || { echo "Thiếu .env.release — xem tool/README-release.md"; exit 1; }
set -a; . ./.env.release; set +a

UPLOAD=1
[ "${1:-}" = "--no-upload" ] && UPLOAD=0

for v in APPLE_ID APPLE_TEAM_ID APPLE_APP_SPECIFIC_PASSWORD; do
  [ -n "${!v:-}" ] || { echo "Thiếu $v trong .env.release"; exit 1; }
done

if [ -x "$HOME/fvm/versions/3.47.5/bin/flutter" ]; then
  export PATH="$HOME/fvm/versions/3.47.5/bin:$PATH"
fi

VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}')
BUILD_NO=${GITHUB_RUN_NUMBER:-$(git rev-list --count HEAD)}
echo "▶ MedOne $VERSION (build $BUILD_NO) → TestFlight"

cat > ios/ExportOptions.plist <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key><string>app-store-connect</string>
  <key>teamID</key><string>${APPLE_TEAM_ID}</string>
  <key>uploadSymbols</key><true/>
  <key>signingStyle</key><string>automatic</string>
  <key>destination</key><string>export</string>
</dict>
</plist>
PLIST

flutter pub get
flutter build ipa --release --build-number="$BUILD_NO" \
  --export-options-plist=ios/ExportOptions.plist 2>&1 | tail -8

IPA=$(ls -t build/ios/ipa/*.ipa 2>/dev/null | head -1)
[ -n "$IPA" ] || { echo "Không dựng được IPA"; exit 1; }
echo "✔ IPA: $IPA"

[ "$UPLOAD" = "1" ] || exit 0

echo "→ Kiểm tra gói trước khi nạp…"
xcrun altool --validate-app -f "$IPA" -t ios \
  -u "$APPLE_ID" -p "$APPLE_APP_SPECIFIC_PASSWORD" 2>&1 | tail -5

echo "→ Nạp lên App Store Connect…"
xcrun altool --upload-app -f "$IPA" -t ios \
  -u "$APPLE_ID" -p "$APPLE_APP_SPECIFIC_PASSWORD" 2>&1 | tail -5
echo "✔ Đã nạp. App Store Connect xử lý xong sẽ hiện ở TestFlight (thường 5–20 phút)."

if [ -n "${TELEGRAM_BOT_TOKEN:-}" ] && [ -n "${TELEGRAM_CHAT_ID_BAPP:-}" ]; then
  curl -sS -F "chat_id=${TELEGRAM_CHAT_ID_BAPP}" \
    -F "text=MedOne $VERSION · build $BUILD_NO đã nạp lên TestFlight." \
    "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" >/dev/null
fi
