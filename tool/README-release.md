# Phát hành MedOne

## Bí mật

Mọi mật khẩu/token nằm ở `.env.release` **ngoài git** (`.gitignore`), quyền `600`.
Mẫu:

```sh
TELEGRAM_BOT_TOKEN=          # token BotFather của @oscarminbot
TELEGRAM_CHAT_ID_BAPP=       # id nhóm BAPP (số âm, ví dụ -1001234567890)
TELEGRAM_CHAT_ID_APP=        # id nhóm APP
APPLE_ID=                    # email Apple ID dùng cho App Store Connect
APPLE_TEAM_ID=               # 10 ký tự, xem developer.apple.com → Membership
APPLE_APP_SPECIFIC_PASSWORD= # dạng xxxx-xxxx-xxxx-xxxx
ANDROID_KEYSTORE_PASSWORD=   # sinh tự động khi tạo keystore
```

Khoá ký Android: `android/app/medone-upload.jks` + `android/key.properties`, cả hai đều
ngoài git. **Mất keystore là không cập nhật được bản đã lên Play Store** — sao lưu chỗ khác.

## Android → APK gửi Telegram

```sh
tool/release.sh                # build APK release rồi gửi vào BAPP và APP
tool/release.sh --no-send      # chỉ build
tool/release.sh --group BAPP   # chỉ gửi một nhóm
```

Số build lấy từ `GITHUB_RUN_NUMBER` khi chạy trong CI, không thì lấy theo giờ (`yymmddHHMM`).

Giới hạn: Telegram Bot API chỉ nhận tệp **≤ 50MB**, nên script gửi bản `arm64-v8a`
(~36MB) chứ không phải bản gộp (~85MB). Bản gộp không còn được dựng.

Nhóm **BAPP là channel**, bot phải có quyền quản trị mới đăng được; hiện để trống nên
script bỏ qua. Muốn bật thì cấp quyền quản trị cho bot rồi điền lại id `-1003708073508`.

### Lấy chat id của nhóm

1. Thêm `@oscarminbot` vào nhóm và cấp quyền quản trị (hoặc tắt privacy mode ở BotFather:
   `/setprivacy` → `Disable`).
2. Gõ một tin bất kỳ trong nhóm, ví dụ `/id@oscarminbot`.
3. Chạy `tool/telegram-chats.sh` — script in ra tên nhóm kèm id.

## iOS → TestFlight

```sh
tool/testflight.sh             # build IPA + validate + upload
tool/testflight.sh --no-upload # chỉ dựng IPA
```

Máy phải đã đăng nhập Xcode bằng tài khoản có quyền ký cho `com.labasset.app`, và app
đã được tạo sẵn trong App Store Connect. `ios/ExportOptions.plist` do script sinh ra.

## Tự động trên CI

`.github/workflows/release.yml` chạy khi đẩy tag `v*` hoặc bấm tay:
- job `android` dựng APK ký thật rồi gửi Telegram;
- job `ios` chạy trên `macos-latest`, dựng IPA và nạp TestFlight.

Bí mật khai trong **Settings → Secrets and variables → Actions**, đúng tên biến ở trên,
thêm `ANDROID_KEYSTORE_BASE64` (kết quả của `base64 -i android/app/medone-upload.jks`).
