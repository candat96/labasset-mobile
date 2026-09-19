import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../core/cache/kv_cache.dart';
import '../../core/errors/api_error.dart';
import '../../core/services/attachment_service.dart';
import '../../core/sync/outbox_service.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../data/models/maintenance.dart';
import '../../data/repositories/tasks_repository.dart';

/// Handler outbox cho kết quả checklist (clientVersion, phát hiện stale).
class TaskResultOutboxHandler implements OutboxHandler {
  TaskResultOutboxHandler(this.tasks);

  final TasksRepository tasks;

  static const typeName = 'task_result';

  @override
  String get type => typeName;

  @override
  Future<void> send(Map<String, dynamic> payload) async {
    final results = (payload['results'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(TaskResult.fromJson)
        .toList();
    await tasks.saveResults(
      payload['taskId'] as String,
      clientVersion: (payload['clientVersion'] as num?) ?? 0,
      results: results,
    );
  }
}

/// Chi tiết công việc bảo dưỡng: checklist + nháp offline + stale version + hoàn thành.
class MaintenanceTaskController extends GetxController {
  MaintenanceTaskController({
    required this.tasks,
    required this.outbox,
    required this.cache,
    required this.id,
    this.userId = '',
    this.roles = const [],
    this.attachments,
  });

  final TasksRepository tasks;
  final OutboxService outbox;
  final KvCache cache;
  final String id;
  final String userId;
  final List<String> roles;
  final AttachmentService? attachments;

  final Rxn<MaintenanceTask> item = Rxn<MaintenanceTask>();
  final RxBool loading = true.obs;
  final Rxn<Object> error = Rxn<Object>();

  /// Kết quả theo từng mục checklist (key → result).
  final RxMap<String, TaskResult> results = <String, TaskResult>{}.obs;
  final Map<String, TextEditingController> valueControllers = {};
  final Map<String, TextEditingController> noteControllers = {};

  final RxBool draftRestored = false.obs;
  final RxBool saving = false.obs;
  final RxBool staleVersion = false.obs;
  final RxSet<String> missingKeys = <String>{}.obs;

  Timer? _debounce;

  bool get isAdmin => roles.contains('HOSPITAL_ADMIN');
  bool get canStart =>
      item.value?.status == 'scheduled' || item.value?.status == 'overdue';
  bool get canWork => item.value?.status == 'in_progress';
  bool get canFinish => canWork;

  String draftKey(String taskId) => 'maintenance.draft.$taskId';

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final t = await tasks.detail(id);
      item.value = t;
      _seedFrom(t.results);
      await _restoreDraft(t);
    } catch (e) {
      error.value = e;
    } finally {
      loading.value = false;
    }
  }

  void _seedFrom(List<TaskResult> serverResults) {
    for (final r in serverResults) {
      results[r.key] = r;
    }
  }

  Future<void> _restoreDraft(MaintenanceTask t) async {
    try {
      final cached = await cache.get(draftKey(t.id));
      if (cached == null) return;
      final raw = cached.value['results'];
      if (raw is! List) return;
      for (final m in raw.whereType<Map>()) {
        final r = TaskResult.fromJson(Map<String, dynamic>.from(m));
        results[r.key] = r;
      }
      draftRestored.value = true;
    } catch (_) {
      // draft hỏng → bỏ qua
    }
  }

  TaskResult _resultOf(String key) => results[key] ?? TaskResult(key: key);

  void setCheck(String key, bool? pass) {
    results[key] = _resultOf(key).copyWith(pass: pass);
    _touch();
  }

  void setValue(String key, String? value) {
    final item = _itemOf(key);
    bool? pass;
    if (item?.type == 'measure' && value != null && value.isNotEmpty) {
      final num = double.tryParse(value.replaceAll(',', '.'));
      if (num != null) {
        final min = item?.min;
        final max = item?.max;
        pass = (min == null || num >= min) && (max == null || num <= max);
      }
    }
    results[key] = _resultOf(key).copyWith(value: value, pass: pass);
    _touch();
  }

  void setNote(String key, String note) {
    results[key] = _resultOf(key).copyWith(note: note);
    _touch();
  }

  ChecklistItem? _itemOf(String key) {
    for (final i in item.value?.templateItems ?? const <ChecklistItem>[]) {
      if (i.key == key) return i;
    }
    return null;
  }

  /// Gắn ảnh cho mục: chọn ảnh → upload ngay → lưu photoFileId.
  Future<void> attachPhoto(String key) async {
    final service = attachments;
    if (service == null) return;
    final picked = await service.pickImageBytes();
    if (picked == null) return;
    try {
      final upload = await service.uploadBytes(
        entityType: 'maintenance_task',
        entityId: id,
        kind: 'checklist_item',
        name: picked.name,
        mime: picked.mime,
        bytes: picked.bytes,
      );
      final fileId = upload.attachment?.fileId;
      if (fileId != null) {
        results[key] = _resultOf(key).copyWith(photoFileId: fileId);
        _touch();
      } else {
        AppSnackbar.info('attachment.queued'.tr);
      }
    } catch (e) {
      AppSnackbar.error(e);
    }
  }

  void _touch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 1), () => persistDraft());
  }

  /// Lưu nháp: local (sqflite) + đẩy PUT results qua outbox.
  Future<void> persistDraft() async {
    saving.value = true;
    try {
      final t = item.value;
      if (t == null) return;
      await cache.put(draftKey(t.id), {
        'results': results.values.map((r) => r.toJson()).toList(),
      });
      await outbox.enqueue(TaskResultOutboxHandler.typeName, {
        'taskId': t.id,
        'clientVersion': t.clientVersion,
        'results': results.values.map((r) => r.toJson()).toList(),
      });
      await outbox.run();
    } catch (_) {
      // nháp local vẫn còn
    } finally {
      saving.value = false;
    }
  }

  // ── Hành động ──────────────────────────────────────────────
  Future<bool> start({String? qrToken}) async {
    try {
      await tasks.start(id, equipmentQrToken: qrToken);
      await load();
      return true;
    } catch (e) {
      final err = ApiError.from(e);
      if (err.code == 'MAINT_QR_MISMATCH') {
        AppSnackbar.error(e);
      } else {
        AppSnackbar.error(e);
      }
      return false;
    }
  }

  Future<bool> skip(String reason) async {
    try {
      await tasks.skip(id, reason);
      await load();
      return true;
    } catch (e) {
      AppSnackbar.error(e);
      return false;
    }
  }

  Future<bool> finish({required bool overallPass, String? notes}) async {
    try {
      await tasks.finish(id, overallPass: overallPass, notes: notes);
      missingKeys.clear();
      await _clearDraft();
      await load();
      return true;
    } catch (e) {
      final err = ApiError.from(e);
      if (err.code == 'MAINT_STALE_VERSION') {
        staleVersion.value = true;
        AppSnackbar.info('errors.MAINT_STALE_VERSION'.tr);
      } else {
        _highlightMissing(err);
        AppSnackbar.error(e);
      }
      return false;
    }
  }

  void _highlightMissing(ApiError err) {
    final d = err.details;
    final keys = <String>{};
    if (d is Map && d['keys'] is List) {
      keys.addAll((d['keys'] as List).whereType<String>());
    } else if (d is List) {
      keys.addAll(d.whereType<String>());
    }
    missingKeys.assignAll(keys);
  }

  /// Xử lý stale: giữ bản local (đẩy lại với version mới) hay tải lại server.
  Future<void> resolveStale({required bool keepLocal}) async {
    staleVersion.value = false;
    if (!keepLocal) {
      await _clearDraft();
      await load();
      return;
    }
    await load();
    await persistDraft();
  }

  Future<void> _clearDraft() async {
    try {
      await cache.delete(draftKey(id));
    } catch (_) {}
  }

  Future<void> sign({required String role, required String signerName}) async {
    final service = attachments;
    if (service == null) return;
    final picked = await service.pickImageBytes();
    if (picked == null) return;
    try {
      final upload = await service.uploadBytes(
        entityType: 'maintenance_task',
        entityId: id,
        kind: role == 'technician'
            ? 'signature_technician'
            : 'signature_department',
        name: 'chu-ky-$role.png',
        mime: picked.mime,
        bytes: picked.bytes,
      );
      final fileId = upload.attachment?.fileId;
      if (fileId == null) return;
      await tasks.addSignature(
        id,
        role: role,
        signerName: signerName,
        fileId: fileId,
      );
      AppSnackbar.success('repairs.sign.saved'.tr);
      await load();
    } catch (e) {
      AppSnackbar.error(e);
    }
  }

  @override
  void onClose() {
    _debounce?.cancel();
    for (final c in valueControllers.values) {
      c.dispose();
    }
    for (final c in noteControllers.values) {
      c.dispose();
    }
    super.onClose();
  }
}
