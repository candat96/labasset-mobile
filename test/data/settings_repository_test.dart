import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:labasset_mobile/data/models/attachment.dart';
import 'package:labasset_mobile/data/repositories/settings_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  setUpAll(() {
    registerFallbackValue(RequestOptions(path: '/'));
  });

  test('settings/public: hospital.name + pushEnabled + repairSla', () async {
    final dio = _MockDio();
    when(() => dio.get<Map<String, dynamic>>(any())).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/v1/settings/public'),
        data: const {
          'hospital.name': 'Bệnh viện Demo',
          'pushEnabled': true,
          'repairSla': {'low': 168, 'medium': 72, 'high': 24, 'critical': 4},
        },
      ),
    );
    final repo = SettingsRepository(dio);
    expect(await repo.hospitalName(), 'Bệnh viện Demo');
    expect(await repo.pushEnabled(), isTrue);
    final sla = await repo.repairSla();
    expect(sla['critical'], 4);
    expect(sla['medium'], 72);
  });

  test('settings/public lỗi → trả null/false/rỗng, không ném', () async {
    final dio = _MockDio();
    when(
      () => dio.get<Map<String, dynamic>>(any()),
    ).thenThrow(Exception('offline'));
    final repo = SettingsRepository(dio);
    expect(await repo.hospitalName(), isNull);
    expect(await repo.pushEnabled(), isFalse);
    expect(await repo.repairSla(), isEmpty);
  });

  test('AttachmentView có mime/name/size (B6-B13)', () {
    final a = AttachmentView.fromJson(const {
      'id': 'a1',
      'fileId': 'f1',
      'entityType': 'equipment',
      'entityId': 'e1',
      'kind': 'photo',
      'label': '',
      'sortOrder': 0,
      'createdBy': 'u1',
      'mime': 'image/jpeg',
      'name': 'anh-1.jpg',
      'size': 12345,
    });
    expect(a.isImage, isTrue);
    expect(a.displayName, 'anh-1.jpg');
    expect(a.size, 12345);
  });
}
