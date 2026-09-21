import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:labasset_mobile/core/i18n/app_translations.dart';
import 'package:labasset_mobile/modules/repairs/repair_detail_view.dart';

void main() {
  setUpAll(() {
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('vi', 'VN');
  });

  test('repairLogLabel dịch mã enum của API sang tiếng Việt', () {
    expect(repairLogLabel('created'), 'Tạo phiếu');
    expect(repairLogLabel('accepted'), 'Tiếp nhận phiếu');
    expect(repairLogLabel('status:in_progress'), 'Đổi trạng thái → Đang sửa');
    expect(
      repairLogLabel('assignment:declined'),
      'Phản hồi phân công: Từ chối',
    );
    expect(repairLogLabel('acceptance_rejected'), 'Nghiệm thu không đạt');
  });

  test('repairLogLabel giữ nguyên chuỗi tự nhập', () {
    expect(repairLogLabel('Thay bo mạch nguồn'), 'Thay bo mạch nguồn');
  });
}
