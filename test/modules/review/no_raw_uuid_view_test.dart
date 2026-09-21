import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:labasset_mobile/core/format/display_text.dart';

void main() {
  test('UUID detector chặn mã kỹ thuật, giữ tên tự nhiên', () {
    expect(isUuidText('461175b0-e8fb-4118-bb19-c32b3077b0db'), isTrue);
    expect(
      displayNameOr('461175b0-e8fb-4118-bb19-c32b3077b0db', 'Nhà cung cấp'),
      'Nhà cung cấp',
    );
    expect(
      displayNameOr('Công ty Thiết bị A', 'Nhà cung cấp'),
      'Công ty Thiết bị A',
    );
  });

  test('5 màn chi tiết chính không render trực tiếp field ID bằng Text', () {
    const files = [
      'lib/modules/repairs/repair_detail_view.dart',
      'lib/modules/requests/request_detail_view.dart',
      'lib/modules/stock/issue_detail_view.dart',
      'lib/modules/stock/receipts_view.dart',
      'lib/modules/stock/supply_detail_view.dart',
    ];
    final rawIdText = RegExp(r'Text\([^\n]*(?:[A-Za-z]+Id|\.id)\b');
    for (final path in files) {
      final source = File(path).readAsStringSync();
      expect(
        rawIdText.hasMatch(source),
        isFalse,
        reason: '$path còn render ID thô trong Text(...)',
      );
    }
  });
}
