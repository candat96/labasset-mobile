import 'dart:io';

import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Mở PDF bằng ứng dụng ngoài hoặc chia sẻ file đã tạo cục bộ.
class PdfFileService {
  PdfFileService._();

  static Future<void> open(File file) async {
    final opened = await launchUrl(
      Uri.file(file.path),
      mode: LaunchMode.externalApplication,
    );
    if (!opened) throw StateError('pdf_open_failed');
  }

  static Future<void> share(File file) =>
      SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
}
