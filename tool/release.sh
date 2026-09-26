#!/usr/bin/env bash
# Build APK phát hành của MedOne rồi gửi vào nhóm Telegram.
#
#   tool/release.sh              # build + gửi vào cả hai nhóm đã cấu hình
#   tool/release.sh --no-send    # chỉ build
#   tool/release.sh --group BAPP # chỉ gửi một nhóm
#
# Bí mật đọc từ .env.release (ngoài git). Xem tool/README-release.md.
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT=$(pwd)

[ -f .env.release ] || { echo "Thiếu .env.release — xem tool/README-release.md"; exit 1; }
set -a; . ./.env.release; set +a

SEND=1
ONLY_GROUP=""
while [ $# -gt 0 ]; do
  case "$1" in
    --no-send) SEND=0 ;;
    --group) ONLY_GROUP="$2"; shift ;;
    *) echo "Tham số lạ: $1"; exit 2 ;;
  esac
  shift
done

# fvm nếu có, không thì flutter trong PATH
if [ -x "$HOME/fvm/versions/3.47.5/bin/flutter" ]; then
  export PATH="$HOME/fvm/versions/3.47.5/bin:$PATH"
fi

VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}')
# versionCode của Android tối đa 2100000000, nên dùng số commit (tăng dần, nhỏ gọn).
BUILD_NO=${GITHUB_RUN_NUMBER:-$(git rev-list --count HEAD)}
STAMP=$(date +%y%m%d-%H%M)
COMMIT=$(git rev-parse --short HEAD)
BRANCH=$(git rev-parse --abbrev-ref HEAD)

echo "▶ MedOne $VERSION (build $BUILD_NO) — $BRANCH@$COMMIT"
flutter pub get
flutter build apk --release --build-number="$BUILD_NO" 2>&1 | tail -5

APK="$ROOT/build/app/outputs/flutter-apk/app-release.apk"
[ -f "$APK" ] || { echo "Không thấy APK: $APK"; exit 1; }
OUT="$ROOT/build/medone-${VERSION%%+*}-b${BUILD_NO}-${STAMP}.apk"
cp "$APK" "$OUT"
SIZE=$(du -h "$OUT" | awk '{print $1}')
echo "✔ APK: $OUT ($SIZE)"

[ "$SEND" = "1" ] || exit 0
[ -n "${TELEGRAM_BOT_TOKEN:-}" ] || { echo "Thiếu TELEGRAM_BOT_TOKEN"; exit 1; }

CAPTION="MedOne $VERSION · build $BUILD_NO ($STAMP)
Nhánh $BRANCH · commit $COMMIT
$(git log -1 --pretty=%s)"

send_to() {
  local name="$1" chat="$2"
  [ -n "$chat" ] || { echo "· Bỏ qua $name (chưa có chat id)"; return 0; }
  echo "→ Gửi $name ($chat)…"
  local res
  res=$(curl -sS -F "chat_id=$chat" -F "caption=$CAPTION" -F "document=@$OUT" \
        "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendDocument")
  python3 -c "
import sys,json
d=json.loads(sys.argv[1])
print('  ✔ đã gửi' if d.get('ok') else '  ✖ lỗi: '+str(d.get('description')))
sys.exit(0 if d.get('ok') else 1)" "$res"
}

RC=0
if [ -z "$ONLY_GROUP" ] || [ "$ONLY_GROUP" = "BAPP" ]; then
  send_to BAPP "${TELEGRAM_CHAT_ID_BAPP:-}" || RC=1
fi
if [ -z "$ONLY_GROUP" ] || [ "$ONLY_GROUP" = "APP" ]; then
  send_to APP "${TELEGRAM_CHAT_ID_APP:-}" || RC=1
fi
exit $RC
