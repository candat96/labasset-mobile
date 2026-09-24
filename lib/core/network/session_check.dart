import '../../data/repositories/auth_repository.dart';
import '../errors/api_error.dart';
import '../storage/session_store.dart';

/// Xác thực lại phiên đã lưu khi mở app bằng `GET /v1/auth/me`.
///
/// Luồng auth: đăng nhập API → lưu token (secure storage) → mở app lần sau chỉ
/// cần token còn hạn là vào thẳng, không phải đăng nhập lại. Hàm này là bước
/// kiểm tra đó:
/// - Token còn hạn → cập nhật lại user (tên/vai trò có thể đã đổi trên server).
/// - 401 → `AuthInterceptor` tự refresh; refresh hỏng → xoá phiên → về `/login`.
/// - Mất mạng → giữ nguyên phiên đã lưu (app vẫn dùng được offline).
///
/// App không phân biệt cài mới hay cài lại: chỉ tin token — cài lại mà Keychain
/// còn token hợp lệ thì vẫn vào thẳng.
Future<void> validateSession({
  required SessionStore store,
  required AuthRepository auth,
}) async {
  if (!store.isLoggedIn) return;
  try {
    await store.setUser(await auth.me());
  } catch (e) {
    final err = ApiError.from(e);
    // Offline: giữ phiên cũ để app chạy tiếp; 401 đã xử lý ở interceptor.
    if (err.status == 0 || err.code == 'NETWORK_ERROR') return;
  }
}
