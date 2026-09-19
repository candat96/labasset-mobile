import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../data/repositories/auth_repository.dart';
import '../data/repositories/device_repository.dart';
import '../data/repositories/equipment_repository.dart';
import '../data/repositories/notifications_repository.dart';
import '../data/repositories/settings_repository.dart';
import 'network/dio_client.dart';
import 'routes/app_routes.dart';
import 'storage/session_store.dart';

/// Khởi tạo dịch vụ dùng chung trước runApp: session, dio, repositories.
Future<void> bootstrap() async {
  final store = await Get.putAsync(
    () => SessionStore().load(),
    permanent: true,
  );
  final dio = createDio(
    store: store,
    onSessionLost: (reason) {
      // Mất phiên (refresh thất bại, tenant bị khoá) → về login với lý do.
      Get.offAllNamed(Routes.login, arguments: {'reason': reason});
    },
  );
  Get.put<Dio>(dio, permanent: true);
  Get.put(AuthRepository(dio), permanent: true);
  Get.put(EquipmentRepository(dio), permanent: true);
  Get.put(NotificationsRepository(dio), permanent: true);
  Get.put(DeviceRepository(dio), permanent: true);
  Get.put(SettingsRepository(dio), permanent: true);
}
