import 'package:json_annotation/json_annotation.dart';

part 'room.g.dart';

/// `RoomResponseDto` / `RoomBriefDto` — vị trí vật lý (`rooms`).
///
/// `departmentId` null = phòng dùng chung (hội trường, kho chung…).
@JsonSerializable()
class RoomRef {
  const RoomRef({
    required this.id,
    required this.code,
    required this.name,
    this.building,
    this.floor,
    this.roomType,
    this.departmentId,
    this.departmentCode,
  });

  final String id;
  final String code;
  final String name;
  final String? building;
  final String? floor;
  final String? roomType;
  final String? departmentId;
  final String? departmentCode;

  /// `Toà · Tầng` (bỏ phần rỗng).
  String? get placeText {
    final parts = [
      building,
      floor,
    ].where((e) => e != null && e.trim().isNotEmpty).cast<String>();
    return parts.isEmpty ? null : parts.join(' · ');
  }

  factory RoomRef.fromJson(Map<String, dynamic> json) =>
      _$RoomRefFromJson(json);
  Map<String, dynamic> toJson() => _$RoomRefToJson(this);
}
