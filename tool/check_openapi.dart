// Đối chiếu path trong lib/data/api/endpoints.dart với openapi.json của labasset-api.
// Dùng: dart run tool/check_openapi.dart [đường dẫn openapi.json]
import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final specPath = args.isNotEmpty ? args[0] : '../labasset-api/openapi.json';
  final specFile = File(specPath);
  if (!specFile.existsSync()) {
    stderr.writeln('[check_openapi] không thấy $specPath — bỏ qua');
    exit(0);
  }
  final spec = jsonDecode(specFile.readAsStringSync()) as Map<String, dynamic>;
  final paths = (spec['paths'] as Map<String, dynamic>).keys.toSet();

  final src = File('lib/data/api/endpoints.dart').readAsStringSync();
  final used = RegExp(r"'(/(?:v1|health|sys)[^']*)'")
      .allMatches(src)
      .map((m) => m.group(1)!)
      // `$id` / `${Uri.encodeComponent(token)}` → `{param}`
      .map(
        (p) => p.replaceAllMapped(RegExp(r'\$\{[^}]*\}|\$\w+'), (_) => '{p}'),
      )
      .toSet();

  bool matches(String used) {
    final pattern = RegExp(
      '^${RegExp.escape(used).replaceAll(r'\{p\}', r'\{[^/]+\}')}\$',
    );
    return paths.any(pattern.hasMatch);
  }

  final missing = used.where((u) => !matches(u)).toList()..sort();
  if (missing.isEmpty) {
    stdout.writeln('[check_openapi] OK — ${used.length} path khớp OpenAPI');
    return;
  }
  stderr.writeln('[check_openapi] Path KHÔNG có trong OpenAPI:');
  for (final m in missing) {
    stderr.writeln('  - $m');
  }
  exit(1);
}
