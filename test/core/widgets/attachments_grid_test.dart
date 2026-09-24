import 'dart:typed_data';

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
import 'package:image_picker/image_picker.dart';

import '../../helpers/test_helpers.dart';

class _MockService extends Mock implements AttachmentService {}

class _MockAttachments extends Mock implements AttachmentsRepository {}

class _MockFiles extends Mock implements FilesRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue((
      bytes: Uint8List(0),
      name: 'x.jpg',
      mime: 'image/jpeg',
    ));
  });

  setUp(() {
    Get.testMode = true;
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('vi', 'VN');
  });

  tearDown(Get.reset);

  for (final entityType in ['repair_ticket', 'maintenance_task']) {
    testWidgets(
      '$entityType thêm ảnh qua ô "+": sheet nguồn, không gắn vào máy',
      (tester) async {
        final service = _MockService();
        final attachments = _MockAttachments();
        when(() => service.attachments).thenReturn(attachments);
        when(
          () => attachments.list(
            entityType: entityType,
            entityId: any(named: 'entityId'),
          ),
        ).thenAnswer((_) async => const []);
        when(
          () => service.pickImageBytes(source: ImageSource.camera),
        ).thenAnswer((_) async => null);
        Get.put<AttachmentService>(service);
        await tester.pumpWidget(
          wrap(
            Scaffold(
              body: AttachmentsGrid(
                entityType: entityType,
                entityId: 'order-1',
                photosOnly: true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.add_a_photo_outlined), findsOneWidget);
        await tester.tap(find.byIcon(Icons.add_a_photo_outlined));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Chụp ảnh'));
        await tester.pumpAndSettle();
        verify(
          () => service.pickImageBytes(source: ImageSource.camera),
        ).called(1);
        await tester.pumpWidget(
          wrap(
            Scaffold(
              body: AttachmentsGrid(
                entityType: entityType,
                entityId: 'order-2',
                photosOnly: true,
                canEdit: false,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        verify(
          () => attachments.list(entityType: entityType, entityId: 'order-2'),
        ).called(1);
        expect(find.byIcon(Icons.add_a_photo_outlined), findsNothing);
        expect(find.text('Chụp ảnh'), findsNothing);
        expect(find.text('Chọn từ thư viện'), findsNothing);
        verifyNever(
          () => attachments.list(
            entityType: 'equipment',
            entityId: any(named: 'entityId'),
          ),
        );
      },
    );
  }

  testWidgets('chọn nhiều ảnh từ thư viện → tải lên lần lượt', (tester) async {
    final service = _MockService();
    final attachments = _MockAttachments();
    when(() => service.attachments).thenReturn(attachments);
    when(
      () => attachments.list(entityType: 'repair_ticket', entityId: 'r1'),
    ).thenAnswer((_) async => const []);
    when(() => service.pickImageBytesMulti()).thenAnswer(
      (_) async => [
        (bytes: Uint8List.fromList([1]), name: 'a.jpg', mime: 'image/jpeg'),
        (bytes: Uint8List.fromList([2]), name: 'b.jpg', mime: 'image/jpeg'),
      ],
    );
    when(
      () => service.uploadPicked(
        entityType: 'repair_ticket',
        entityId: 'r1',
        kind: 'photo',
        picked: any(named: 'picked'),
      ),
    ).thenAnswer(
      (_) async =>
          const AttachmentUploadResult(AttachmentUploadStatus.uploaded),
    );
    Get.put<AttachmentService>(service);

    await tester.pumpWidget(
      wrap(
        const Scaffold(
          body: AttachmentsGrid(
            entityType: 'repair_ticket',
            entityId: 'r1',
            photosOnly: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add_a_photo_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chọn từ thư viện'));
    await tester.pumpAndSettle();

    verify(() => service.pickImageBytesMulti()).called(1);
    verify(
      () => service.uploadPicked(
        entityType: 'repair_ticket',
        entityId: 'r1',
        kind: 'photo',
        picked: any(named: 'picked'),
      ),
    ).called(2);
    expect(find.text('Đã tải 2 ảnh lên'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hidePhotos ẩn ảnh khỏi mục tệp đính kèm', (tester) async {
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
          entityType: 'repair_ticket',
          entityId: 'r1',
          kind: 'photo',
          label: 'anh-1.jpg',
        ),
        AttachmentView(
          id: 'a2',
          fileId: 'f2',
          entityType: 'repair_ticket',
          entityId: 'r1',
          kind: 'other',
          label: 'bien-ban.pdf',
        ),
      ],
    );
    when(() => files.url(any())).thenAnswer(
      (_) async => const FileUrl(url: 'https://s3/f', expiresIn: 60),
    );
    Get.put<AttachmentService>(service);

    await tester.pumpWidget(
      wrap(
        const Scaffold(
          body: AttachmentsGrid(
            entityType: 'repair_ticket',
            entityId: 'r1',
            hidePhotos: true,
            kinds: ['other'],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('bien-ban.pdf'), findsOneWidget);
    expect(find.text('anh-1.jpg'), findsNothing);
    expect(find.byType(Image), findsNothing);
  });

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
    expect(find.text('Hướng dẫn sử dụng'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget); // ảnh kind photo
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
