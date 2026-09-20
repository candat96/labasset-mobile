import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:labasset_mobile/core/errors/api_error.dart';
import 'package:labasset_mobile/core/services/attachment_service.dart';
import 'package:labasset_mobile/core/sync/outbox_service.dart';
import 'package:labasset_mobile/data/models/attachment.dart';
import 'package:labasset_mobile/data/repositories/attachments_repository.dart';
import 'package:labasset_mobile/data/repositories/files_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockAttachments extends Mock implements AttachmentsRepository {}

class _MockFiles extends Mock implements FilesRepository {}

class _MockOutbox extends Mock implements OutboxService {}

class _MockDio extends Mock implements Dio {}

class _MockAttachmentService extends Mock implements AttachmentService {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(Options());
  });

  late _MockAttachments attachments;
  late _MockFiles files;
  late _MockOutbox outbox;
  late _MockDio uploadDio;
  late AttachmentService service;

  final bytes = Uint8List.fromList([1, 2, 3]);
  const view = AttachmentView(
    id: 'a1',
    fileId: 'f1',
    entityType: 'equipment',
    entityId: 'e1',
    kind: 'photo',
  );

  setUp(() {
    attachments = _MockAttachments();
    files = _MockFiles();
    outbox = _MockOutbox();
    uploadDio = _MockDio();
    service = AttachmentService(
      attachments: attachments,
      files: files,
      outbox: outbox,
      uploadDio: uploadDio,
      persist: (b, n) async => '/tmp/$n',
    );
  });

  test('presign → PUT → complete → gắn attachment', () async {
    when(
      () => files.presign(
        name: any(named: 'name'),
        mime: any(named: 'mime'),
        size: any(named: 'size'),
      ),
    ).thenAnswer(
      (_) async => const PresignResult(
        fileId: 'f1',
        uploadUrl: 'https://s3/put',
        headers: {'x-amz-acl': 'private'},
      ),
    );
    when(
      () => uploadDio.put<void>(
        any(),
        data: any(named: 'data'),
        options: any(named: 'options'),
      ),
    ).thenAnswer((_) async => Response<void>(requestOptions: RequestOptions()));
    when(() => files.complete('f1')).thenAnswer((_) async {});
    when(
      () => attachments.create(
        entityType: any(named: 'entityType'),
        entityId: any(named: 'entityId'),
        fileId: any(named: 'fileId'),
        kind: any(named: 'kind'),
        label: any(named: 'label'),
      ),
    ).thenAnswer((_) async => view);

    final result = await service.uploadBytes(
      entityType: 'equipment',
      entityId: 'e1',
      kind: 'photo',
      name: 'a.jpg',
      mime: 'image/jpeg',
      bytes: bytes,
    );
    expect(result.status, AttachmentUploadStatus.uploaded);
    expect(result.attachment?.id, 'a1');
    verify(() => files.complete('f1')).called(1);
  });

  test('mất mạng → lưu tệp và xếp hàng outbox', () async {
    when(
      () => files.presign(
        name: any(named: 'name'),
        mime: any(named: 'mime'),
        size: any(named: 'size'),
      ),
    ).thenThrow(ApiError(0, 'NETWORK_ERROR', ''));
    when(() => outbox.enqueue(any(), any())).thenAnswer((_) async => 'o1');

    final result = await service.uploadBytes(
      entityType: 'equipment',
      entityId: 'e1',
      kind: 'photo',
      name: 'a.jpg',
      mime: 'image/jpeg',
      bytes: bytes,
      outboxPayload: const {'clientId': 'count-client-1'},
    );
    expect(result.status, AttachmentUploadStatus.queued);
    final payload =
        verify(() => outbox.enqueue('attachment', captureAny())).captured.single
            as Map<String, dynamic>;
    expect(payload['path'], '/tmp/a.jpg');
    expect(payload['entityId'], 'e1');
    expect(payload['clientId'], 'count-client-1');
  });

  test('queueOnOffline=false → ném lỗi ra ngoài', () async {
    when(
      () => files.presign(
        name: any(named: 'name'),
        mime: any(named: 'mime'),
        size: any(named: 'size'),
      ),
    ).thenThrow(ApiError(0, 'NETWORK_ERROR', ''));
    expect(
      () => service.uploadBytes(
        entityType: 'e',
        entityId: '1',
        kind: 'photo',
        name: 'a.jpg',
        mime: 'image/jpeg',
        bytes: bytes,
        queueOnOffline: false,
      ),
      throwsA(isA<ApiError>()),
    );
  });

  test('lỗi 500 → không xếp hàng, ném ra', () async {
    when(
      () => files.presign(
        name: any(named: 'name'),
        mime: any(named: 'mime'),
        size: any(named: 'size'),
      ),
    ).thenThrow(ApiError(500, 'INTERNAL_ERROR', ''));
    expect(
      () => service.uploadBytes(
        entityType: 'e',
        entityId: '1',
        kind: 'photo',
        name: 'a.jpg',
        mime: 'image/jpeg',
        bytes: bytes,
      ),
      throwsA(isA<ApiError>()),
    );
    verifyNever(() => outbox.enqueue(any(), any()));
  });

  group('AttachmentOutboxHandler', () {
    test('đọc tệp trong payload và gọi uploadBytes', () async {
      final tmp = File(
        '${Directory.systemTemp.path}/labasset-test-${DateTime.now().microsecondsSinceEpoch}.jpg',
      );
      await tmp.writeAsBytes(bytes);
      final mockService = _MockAttachmentService();
      when(
        () => mockService.uploadBytes(
          entityType: any(named: 'entityType'),
          entityId: any(named: 'entityId'),
          kind: any(named: 'kind'),
          name: any(named: 'name'),
          mime: any(named: 'mime'),
          bytes: any(named: 'bytes'),
          label: any(named: 'label'),
          queueOnOffline: false,
        ),
      ).thenAnswer(
        (_) async =>
            const AttachmentUploadResult(AttachmentUploadStatus.uploaded),
      );
      final handler = AttachmentOutboxHandler(mockService);
      expect(handler.type, 'attachment');
      await handler.send({
        'entityType': 'equipment',
        'entityId': 'e1',
        'kind': 'photo',
        'name': 'a.jpg',
        'mime': 'image/jpeg',
        'path': tmp.path,
      });
      verify(
        () => mockService.uploadBytes(
          entityType: 'equipment',
          entityId: 'e1',
          kind: 'photo',
          name: 'a.jpg',
          mime: 'image/jpeg',
          bytes: any(named: 'bytes'),
          label: null,
          queueOnOffline: false,
        ),
      ).called(1);
    });

    test('tệp không còn → lỗi để outbox đánh dấu', () async {
      final handler = AttachmentOutboxHandler(_MockAttachmentService());
      await expectLater(
        () => handler.send({
          'entityType': 'equipment',
          'entityId': 'e1',
          'kind': 'photo',
          'name': 'a.jpg',
          'mime': 'image/jpeg',
          'path': '/tmp/khong-ton-tai.jpg',
        }),
        throwsA(isA<ApiError>()),
      );
    });

    test('thiếu path → bỏ qua', () async {
      final handler = AttachmentOutboxHandler(_MockAttachmentService());
      await handler.send({'entityType': 'equipment'});
    });
  });
}
