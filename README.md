# LabAsset Mobile

App Flutter cho **nhân viên phòng Vật tư – TBYT** và **Admin viện** (dự án con 5). Phục vụ thao tác
tại chỗ: quét QR, sửa chữa, bảo dưỡng, kho, kiểm kê. Hợp đồng với backend là OpenAPI của
`labasset-api`; model Dart viết tay từ `openapi.json` (json_serializable) và được đối chiếu bằng
`tool/check_openapi.dart`.

Tài liệu: `docs/superpowers/specs/2026-09-19-mobile-base-design.md`, design system
`docs/superpowers/specs/2026-09-19-design-system.md` (mục 8 mapping Flutter).

## Stack

Flutter 3.47.5 (FVM) · Dart 3.13 · **GetX** (route + middleware, controller, DI, i18n) · dio · flutter_secure_storage ·
json_serializable · mobile_scanner · local_auth · intl.
Package `labasset_mobile`, id `vn.labasset.mobile`, Android minSdk 24, iOS 15+.

## Chạy

Project bắt buộc Flutter 3.47.5 qua FVM (`.fvmrc`): dùng `fvm flutter ...` và `fvm dart ...` để dependency native như `sqflite` được resolve đúng. iOS dùng CocoaPods: `config: enable-swift-package-manager: false` trong pubspec (SPM mặc định của 3.47 không khớp project Runner); sau `pub get` chạy `cd ios && pod install`.

```bash
fvm flutter pub get
fvm dart run build_runner build -d      # sinh *.g.dart
fvm flutter run --dart-define=API_URL=http://localhost:3969        # iOS simulator
fvm flutter run --dart-define=API_URL=http://10.0.2.2:3969     # Android emulator (mặc định)
fvm flutter run --dart-define=API_URL=http://192.168.1.10:3969 # thiết bị thật (IP LAN máy chạy API)
```

| dart-define | Ý nghĩa |
| --- | --- |
| `API_URL` | Gốc API. Mặc định `http://10.0.2.2:3969` (Android) / `http://localhost:3969` (iOS) |
| `TENANT_MODE` | `multi` \| `single`; bỏ trống → đọc `GET /health` |

API dev: xem README `labasset-api`. Tài khoản `admin` tenant `BVDEMO`; lần đầu `mustChangePassword` →
app ép đổi mật khẩu. App chỉ cho vai trò `HOSPITAL_ADMIN`, `EQUIPMENT_STAFF` (tính năng mobile không
có màn cho khoa) — vai trò khác thấy màn "không hỗ trợ".

## Cấu trúc

```
lib/
  main.dart · app.dart (GetMaterialApp) · core/bootstrap.dart (SessionStore, Dio, repositories, services)
  core/
    config/env.dart          API_URL, TENANT_MODE, resolveTenantMode()
    theme/                   tokens.dart (design system) · app_theme.dart (light/dark, AppStatusColors)
    i18n/                    app_translations.dart · vi.dart (khoá phẳng 'auth.login.title')
    format/format.dart       formatDate/DateTime/Relative, formatVnd(String) không dùng num
    errors/api_error.dart    ApiError {status, code, message, details} · messageFor · fieldErrors
    network/                 dio_client.dart · auth_interceptor.dart (Bearer + X-Tenant-Id, refresh single-flight, retry 1 lần)
    storage/session_store.dart  token secure storage, user Rx, biometric, theme
    routes/                  app_routes.dart · app_pages.dart (nguồn route) · middlewares.dart (Auth/Role/Password)
    widgets/                 EmptyState, ErrorState, StatusBadge, LoadingList, ConfirmSheet, AppSnackbar
  data/
    api/endpoints.dart       MỌI path API (check_openapi đối chiếu)
    models/                  UserView, LoginResult/OtpChallenge/LoginOutcome, SessionView, NotificationItem, Equipment*
    repositories/            Auth, Equipment, Notifications, Device, Settings (nhận Dio)
  modules/
    auth/       login, otp, forgot, change_password, sessions, profile, no_access, auth_pages.dart
    shell/      4 tab (Trang chủ · Sửa chữa · Kho · Cá nhân) + FAB Quét
    home/       việc của tôi / cảnh báo (MOCK có nhãn) + lối tắt module
    scan/       mobile_scanner + nhập tay → by-qr → fallback tìm theo mã → hồ sơ máy
    equipment/  thẻ tóm tắt hồ sơ máy (màn mẫu)
    notifications/  polling 60 s, badge, danh sách
    account/    cài đặt, sinh trắc (lock_controller/lock_view), đăng xuất
    placeholder/ trang "Đang phát triển" (/placeholder/:key)
    feature_pages.dart  route nghiệp vụ
tool/check_openapi.dart · integration_test/smoke_test.dart
```

## Auth & tenant

- Login (`hospitalCode` khi multi) → `LoginResult` hoặc `OtpChallenge` → màn OTP. Token lưu
  `flutter_secure_storage`; `SessionStore.user` là `Rx` để guard/UI phản ứng.
- `AuthInterceptor`: gắn header cho path không public; 401 → refresh **single-flight** (một Completer
  dùng chung), lưu cặp token mới (xoay vòng), gửi lại request gốc một lần (`extra['auth.retried']`);
  refresh thất bại → xoá phiên → `/login` với lý do `expired`. `TENANT_SUSPENDED/MISMATCH` → xoá phiên.
- `mustChangePassword` → `PasswordMiddleware` ép `/change-password`; đổi xong API thu hồi mọi phiên → login lại.
- Sinh trắc: bật trong Cá nhân; `LockController` khoá khi app quay lại sau > 30 s nền; sai 3 lần → đăng xuất.

## Thông báo

Polling `GET /v1/notifications` mỗi 60 s khi foreground (badge = `unreadCount`), danh sách, đọc/đọc tất cả,
mở đối tượng theo `data.path`. **Push (FCM) đã gỡ khỏi base** theo quyết định 2026-09-19; khi cần, thêm
`firebase_messaging` và một `PushService` gọi `DeviceRepository.register/unregister` (đã có sẵn, `POST/DELETE /v1/devices`).

## Quy ước thêm module mới

1. **Endpoint:** thêm hằng vào `lib/data/api/endpoints.dart`; chạy `fvm dart run tool/check_openapi.dart`.
2. **Model:** `lib/data/models/<x>.dart` với `@JsonSerializable()` (field lạ tự bỏ qua) → `build_runner`.
3. **Repository:** `lib/data/repositories/<x>_repository.dart` nhận `Dio`, đăng ký `Get.put` trong `core/bootstrap.dart`.
4. **Module:** `lib/modules/<x>/` gồm `<x>_controller.dart` (GetxController: `loading/error/items` Rx, `load()`),
   `<x>_view.dart` (GetView, dùng `LoadingList`/`ErrorState`/`EmptyState`), binding trong `modules/feature_pages.dart`
   (`GetPage` + `middlewares: protected`).
5. **Route:** hằng trong `core/routes/app_routes.dart`; thay `Routes.placeholderFor('<key>')` ở lối tắt/thao tác nhanh.
6. **i18n:** khoá `'<x>.*'` trong `core/i18n/vi.dart`.
7. **Test:** unit controller với repo mock (mocktail) + `navigate` injection như `ScanController`; widget test với `wrap()` trong `test/helpers`.

Màn mẫu chuẩn: `modules/scan` + `modules/equipment`.

## Test

```bash
fvm flutter analyze && fvm flutter test
fvm flutter test integration_test -d <device> --dart-define=API_URL=... --dart-define=E2E_PASSWORD=... [--dart-define=E2E_EQUIPMENT_CODE=...]
```
Smoke tự skip khi thiếu `E2E_PASSWORD`. CI: format, analyze, test, build apk debug.

## API còn thiếu cho mobile

1. D2 `/v1/ai/*` chưa có — màn Trợ lý AI tiếp tục dùng mock SSE.
2. Gap 26: `StocktakeSessionResponseDto` thiếu `scopeName`, `progressPercent`; quyền đọc items cho `DEPT_USER` còn thiếu.
3. Gap 28: DTO sửa chữa còn thiếu tên khoa/người/NCC và một số quyền workload/log.

D18 `/v1/me/tasks`, D19 `/v1/search` và D1 `/v1/dashboard`, `/v1/reports`, `/v1/reports/{key}` đã được nối API thật.
