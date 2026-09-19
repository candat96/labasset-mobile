import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/i18n/app_translations.dart';
import 'package:labasset_mobile/core/services/attachment_service.dart';
import 'package:labasset_mobile/core/widgets/attachments_grid.dart';
import 'package:labasset_mobile/data/models/attachment.dart';
import 'package:labasset_mobile/data/repositories/attachments_repository.dart';
import 'package:labasset_mobile/data/repositories/files_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_helpers.dart';

class _MockService extends Mock implements AttachmentService {}

class _MockAttachments extends Mock implements AttachmentsRepository {}

class _MockFiles extends Mock implements FilesRepository {}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('vi', 'VN');
  });

  tearDown(Get.reset);

  testWidgets('hiện danh sách tệp, nút thêm khi canEdit', (tester) async {
    final service = _MockService();
    final attachments = _MockAttachments();
    final files = _MockFiles();
    when(() => service.attachments).thenReturn(attachments);
    when(() => service.files).thenReturn(files);
    when(
      () => attachments.list(
        entityType: any(named: 'entityType'),
        entityId: any(named: 'entityId'),
      ),
    ).thenAnswer(
      (_) async => const [
        AttachmentView(
          id: 'a1',
          fileId: 'f1',
          entityType: 'equipment',
          entityId: 'e1',
          kind: 'photo',
          label: 'anh-1.jpg',
        ),
        AttachmentView(
          id: 'a2',
          fileId: 'f2',
          entityType: 'equipment',
          entityId: 'e1',
          kind: 'manual',
        ),
      ],
    );
    when(() => files.url('f1')).thenAnswer(
      (_) async => const FileUrl(url: 'https://s3/f1', expiresIn: 60),
    );
    when(() => files.url('f2')).thenAnswer(
      (_) async => const FileUrl(url: 'https://s3/f2', expiresIn: 60),
    );
    Get.put<AttachmentService>(service);

    await tester.pumpWidget(
      wrap(
        const Scaffold(
          body: AttachmentsGrid(
            entityType: 'equipment',
            entityId: 'e1',
            kinds: ['photo', 'manual'],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tệp đính kèm'), findsOneWidget);
    expect(find.text('anh-1.jpg'), findsOneWidget);
    expect(find.text('Hướng dẫn sử dụng'), findsOneWidget);
    expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
  });

  testWidgets('ẩn nút thêm khi canEdit=false', (tester) async {
    final service = _MockService();
    final attachments = _MockAttachments();
    when(() => service.attachments).thenReturn(attachments);
    when(
      () => attachments.list(
        entityType: any(named: 'entityType'),
        entityId: any(named: 'entityId'),
      ),
    ).thenAnswer((_) async => const []);
    Get.put<AttachmentService>(service);

    await tester.pumpWidget(
      wrap(
        const Scaffold(
          body: AttachmentsGrid(
            entityType: 'equipment',
            entityId: 'e1',
            canEdit: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.add_circle_outline), findsNothing);
    expect(find.text('Chưa có tệp'), findsOneWidget);
  });
}
