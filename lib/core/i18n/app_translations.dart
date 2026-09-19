import 'package:get/get.dart';

import 'vi.dart';

/// Thêm ngôn ngữ: tạo `en.dart` và đăng ký vào `keys`.
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {'vi_VN': vi};
}
