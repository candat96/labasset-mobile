import 'package:flutter/material.dart';

/// Focus + cuộn tới ô nhập đang lỗi để bàn phím không che ô cần sửa.
///
/// Ô lỗi được nhận diện bằng cách đi ngược cây widget từ [FocusNode.context]
/// tới `FormFieldState` gần nhất rồi xem `hasError` — không lặp lại logic
/// validator. Sau `requestFocus()`, [Scrollable.ensureVisible] đưa ô lên sát
/// mép trên của scrollable gần nhất (mặc định `explicit` + `alignment: 0`),
/// nên ô + dòng lỗi dưới nó luôn nằm trên bàn phím; ô đã ở mép trên thì đứng
/// yên (target == pixels).
class FormFocus {
  FormFocus._();

  /// Focus + cuộn tới ô lỗi **đầu tiên** trong [nodes] (theo thứ tự khai báo).
  /// Trả về `true` nếu tìm thấy ô lỗi.
  static bool firstError(List<FocusNode> nodes) {
    for (final node in nodes) {
      if (formFieldOf(node)?.hasError != true) continue;
      reveal(node);
      return true;
    }
    return false;
  }

  /// Focus [node] rồi cuộn ô của nó vào vùng nhìn (sau frame hiện tại).
  static void reveal(FocusNode node) {
    node.requestFocus();
    // Chưa gắn vào cây widget (unit test không binding) → chỉ focus, không cuộn.
    if (node.context == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = node.context;
      if (context == null || !context.mounted) return;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  /// `FormFieldState` bao quanh ô của [node] (null khi ô không nằm trong Form).
  static FormFieldState<dynamic>? formFieldOf(FocusNode node) {
    final context = node.context;
    if (context == null) return null;
    FormFieldState<dynamic>? found;
    context.visitAncestorElements((element) {
      final state = element is StatefulElement ? element.state : null;
      if (state is FormFieldState) {
        found = state;
        return false;
      }
      return true;
    });
    return found;
  }
}
