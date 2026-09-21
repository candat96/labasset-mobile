import 'package:flutter/widgets.dart';

import '../../data/models/department.dart';
import 'picker_sheet.dart';

/// Chọn một tham chiếu (kho / khoa / nhà cung cấp) từ danh sách đã tải,
/// có ô tìm lọc tại chỗ; null khi huỷ hoặc danh sách rỗng.
Future<DepartmentRef?> pickRef(
  BuildContext context, {
  required String title,
  required Future<List<DepartmentRef>> Function() loader,
  PickerKind kind = PickerKind.department,
}) async {
  final list = await loader();
  if (list.isEmpty || !context.mounted) return null;
  final selection = await PickerSheet.show<DepartmentRef>(
    context,
    title: title,
    kind: kind,
    loader: (q) async {
      final needle = q.trim().toLowerCase();
      return [
        for (final d in list)
          if (needle.isEmpty ||
              d.code.toLowerCase().contains(needle) ||
              d.name.toLowerCase().contains(needle))
            PickerOption(value: d, code: d.code, name: d.name),
      ];
    },
  );
  return selection?.option?.value;
}
