import 'package:flutter_test/flutter_test.dart';
import 'package:labasset_mobile/data/models/request_detail.dart';

void main() {
  test('RequestItem đọc tên/mã vật tư từ object supply lồng nhau', () {
    final i = RequestItem.fromJson({
      'id': 'i1',
      'supplyId': 'uuid-1',
      'qtyRequested': '10',
      'supply': {'id': 'uuid-1', 'code': 'VT-01', 'name': 'Găng tay'},
    });
    expect(i.supplyCode, 'VT-01');
    expect(i.supplyName, 'Găng tay');
    expect(i.label, 'VT-01 — Găng tay');
  });

  test('RequestItem không có supply → label là supplyId', () {
    final i = RequestItem.fromJson({
      'id': 'i1',
      'supplyId': 'uuid-1',
      'qtyRequested': '1',
    });
    expect(i.label, 'uuid-1');
  });

  test('RequestComment đọc tên người từ user lồng nhau', () {
    final c = RequestComment.fromJson({
      'id': 'c1',
      'userId': 'u1',
      'body': 'ok',
      'user': {'id': 'u1', 'fullName': 'Trần Thị Bích'},
    });
    expect(c.userName, 'Trần Thị Bích');
  });
}
