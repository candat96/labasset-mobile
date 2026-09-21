import 'package:json_annotation/json_annotation.dart';

import 'room.dart';

part 'global_search.g.dart';

@JsonSerializable(explicitToJson: true)
class GlobalSearchResponse {
  const GlobalSearchResponse({
    required this.equipment,
    required this.supplies,
    required this.repairs,
    required this.requests,
    required this.faults,
  });
  final List<GlobalSearchHit> equipment;
  final List<GlobalSearchHit> supplies;
  final List<GlobalSearchHit> repairs;
  final List<GlobalSearchHit> requests;
  final List<GlobalSearchHit> faults;

  factory GlobalSearchResponse.fromJson(Map<String, dynamic> json) =>
      _$GlobalSearchResponseFromJson(json);
  Map<String, dynamic> toJson() => _$GlobalSearchResponseToJson(this);
}

@JsonSerializable()
class GlobalSearchHit {
  const GlobalSearchHit({
    required this.id,
    required this.code,
    required this.title,
    required this.subtitle,
    required this.link,
    this.room,
  });
  final String id;
  final String code;
  final String title;
  final String subtitle;
  final String link;
  final RoomRef? room;
  factory GlobalSearchHit.fromJson(Map<String, dynamic> json) =>
      _$GlobalSearchHitFromJson(json);
  Map<String, dynamic> toJson() => _$GlobalSearchHitToJson(this);
}
