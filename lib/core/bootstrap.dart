import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../data/repositories/attachments_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/device_repository.dart';
import '../data/repositories/equipment_repository.dart';
import '../data/repositories/files_repository.dart';
import '../data/repositories/notifications_repository.dart';
import '../data/repositories/repairs_repository.dart';
import '../data/repositories/requests_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/supplies_repository.dart';
import '../modules/account/lock_controller.dart';
import '../modules/notifications/notifications_controller.dart';
import 'network/connectivity.dart';
import 'network/dio_client.dart';
import 'routes/app_routes.dart';
import 'services/attachment_service.dart';
import 'storage/session_store.dart';
import 'sync/outbox_service.dart';
import 'sync/outbox_store.dart';

/// Khởi tạo dịch vụ dùng chung trước runApp: session, dio, repositories, outbox.
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
  Get.put(SuppliesRepository(dio), permanent: true);
  Get.put(RepairsRepository(dio), permanent: true);
  Get.put(RequestsRepository(dio), permanent: true);
  Get.put(NotificationsRepository(dio), permanent: true);
  Get.put(DeviceRepository(dio), permanent: true);
  Get.put(SettingsRepository(dio), permanent: true);
  Get.put(AttachmentsRepository(dio), permanent: true);
  Get.put(FilesRepository(dio), permanent: true);

  // Hàng đợi offline: sqflite + lắng nghe mạng, handler tệp đính kèm.
  final outbox = Get.put(
    OutboxService(store: SqfliteOutboxStore(), online: hasNetwork),
    permanent: true,
  );
  await outbox.init();
  final attachments = Get.put(
    AttachmentService(
      attachments: Get.find<AttachmentsRepository>(),
      files: Get.find<FilesRepository>(),
      outbox: outbox,
    ),
    permanent: true,
  );
  outbox.addHandler(AttachmentOutboxHandler(attachments));
  await outbox.start(connectivity: networkChanges());

  // Dịch vụ chạy suốt phiên: thông báo (polling), khoá sinh trắc.
  Get.put(
    NotificationsController(
      store: store,
      repo: Get.find<NotificationsRepository>(),
    ),
    permanent: true,
  );
  Get.put(LockController(store: store), permanent: true);
}
