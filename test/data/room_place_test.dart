import 'package:flutter_test/flutter_test.dart';
import 'package:labasset_mobile/data/models/equipment.dart';
import 'package:labasset_mobile/data/models/equipment_detail.dart';
import 'package:labasset_mobile/data/models/room.dart';

const _room = RoomRef(
  id: 'r1',
  code: 'XN-P01',
  name: 'Phòng Huyết học',
  building: 'Nhà A',
  floor: 'Tầng 1',
);

void main() {
  test('RoomRef.placeText ghép toà · tầng, bỏ phần rỗng', () {
    expect(_room.placeText, 'Nhà A · Tầng 1');
    expect(
      const RoomRef(id: 'r', code: 'c', name: 'n', building: 'Nhà B').placeText,
      'Nhà B',
    );
    expect(const RoomRef(id: 'r', code: 'c', name: 'n').placeText, isNull);
  });

  test('EquipmentSummary.placeText = phòng · vị trí', () {
    const eq = EquipmentSummary(
      id: 'e1',
      code: 'TB-1',
      name: 'Máy',
      status: 'active',
      location: 'Bàn 1',
      room: _room,
    );
    expect(eq.placeText, 'Phòng Huyết học · Bàn 1');
  });

  test('EquipmentSummary.placeText chỉ phòng khi không có vị trí', () {
    const eq = EquipmentSummary(
      id: 'e1',
      code: 'TB-1',
      name: 'Máy',
      status: 'active',
      room: _room,
    );
    expect(eq.placeText, 'Phòng Huyết học');
  });

  test('EquipmentDetail.placeText = phòng · vị trí', () {
    const d = EquipmentDetail(
      id: 'e1',
      code: 'TB-1',
      name: 'Máy',
      status: 'active',
      location: 'Giường H04',
      room: _room,
    );
    expect(d.placeText, 'Phòng Huyết học · Giường H04');
  });

  test('QrEquipment.placeText = phòng · vị trí', () {
    const q = QrEquipment(
      id: 'e1',
      code: 'TB-1',
      name: 'Máy',
      status: 'active',
      location: 'Bàn 2',
      room: _room,
    );
    expect(q.placeText, 'Phòng Huyết học · Bàn 2');
  });

  test('placeText rỗng khi không có phòng lẫn vị trí', () {
    const eq = EquipmentSummary(
      id: 'e1',
      code: 'TB-1',
      name: 'Máy',
      status: 'active',
    );
    expect(eq.placeText, '');
  });
}
