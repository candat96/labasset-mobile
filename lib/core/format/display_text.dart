final _uuidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  caseSensitive: false,
);

bool isUuidText(String? value) =>
    value != null && _uuidPattern.hasMatch(value.trim());

/// Không bao giờ để UUID kỹ thuật lọt ra giao diện khi dữ liệu tên bị thiếu.
String displayNameOr(String? value, String fallback) {
  final text = value?.trim();
  if (text == null || text.isEmpty || isUuidText(text)) return fallback;
  return text;
}
