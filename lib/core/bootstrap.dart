import 'package:dio/dio.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:get/get.dart';

import '../data/repositories/attachments_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/calendar_repository.dart';
import '../data/repositories/catalogs_repository.dart';
import '../data/repositories/departments_repository.dart';
import '../data/repositories/device_repository.dart';
import '../data/repositories/equipment_repository.dart';
import '../data/repositories/faults_repository.dart';
import '../data/repositories/files_repository.dart';
import '../data/repositories/notifications_repository.dart';
import '../data/repositories/repairs_repository.dart';
import '../data/repositories/requests_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/stock_repository.dart';
import '../data/repositories/supplies_repository.dart';
import '../data/repositories/tasks_repository.dart';
import '../modules/account/lock_controller.dart';
import '../modules/notifications/notifications_controller.dart';
import '../modules/repairs/repair_detail_controller.dart';
import 'cache/kv_cache.dart';
import 'network/connectivity.dart';
import 'network/dio_client.dart';
import 'routes/app_routes.dart';
import 'services/attachment_service.dart';
import 'storage/session_store.dart';
import 'sync/outbox_service.dart';
import 'sync/outbox_store.dart';

/// Khởi tạo dịch vụ dùng chung trước runApp: session, dio, repositories, outbox.
Future<void> bootstrap() async {
  await initializeDateFormatting('vi_VN');
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
  Get.put(TasksRepository(dio), permanent: true);
  Get.put(StockRepository(dio), permanent: true);
  Get.put(DepartmentsRepository(dio), permanent: true);
  Get.put(FaultsRepository(dio), permanent: true);
  Get.put(CatalogsRepository(dio), permanent: true);
  Get.put(CalendarRepository(dio), permanent: true);

  // Cache khoá–giá trị (trang chủ offline, lịch sử quét…).
  final cache = Get.put(SqfliteKvCache(), permanent: true);
  await cache.init();

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
  outbox.addHandler(RepairLogOutboxHandler(Get.find<RepairsRepository>()));
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
