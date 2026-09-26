#!/usr/bin/env bash
# In ra các cuộc trò chuyện mà bot đang thấy, kèm chat id để điền vào .env.release.
set -euo pipefail
cd "$(dirname "$0")/.."
[ -f .env.release ] || { echo "Thiếu .env.release"; exit 1; }
set -a; . ./.env.release; set +a

curl -sS "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getUpdates" | python3 -c '
import sys, json
d = json.load(sys.stdin)
if not d.get("ok"):
    print("Lỗi:", d.get("description"))
    print("Token sai hoặc đã bị thu hồi — lấy lại ở BotFather: /mybots → chọn bot → API Token.")
    sys.exit(1)
seen = {}
for u in d.get("result", []):
    for k in ("message", "channel_post", "my_chat_member", "edited_message"):
        c = (u.get(k) or {}).get("chat")
        if c:
            seen[c["id"]] = c.get("title") or c.get("username") or c.get("first_name") or "?"
if not seen:
    print("Bot chưa thấy cuộc trò chuyện nào.")
    print("Thêm bot vào nhóm rồi gõ một tin trong nhóm, sau đó chạy lại.")
    sys.exit(1)
for cid, name in seen.items():
    print(f"{cid}\t{name}")
'
