import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/widgets/empty_state.dart';

/// Trang giữ chỗ cho mọi màn chưa triển khai: `/placeholder/:key`.
class PlaceholderView extends StatelessWidget {
  const PlaceholderView({super.key, this.keyName});

  final String? keyName;

  @override
  Widget build(BuildContext context) {
    final key = keyName ?? Get.parameters['key'] ?? 'unknown';
    final name = 'placeholder.$key'.tr;
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: EmptyState(
        icon: Icons.construction_outlined,
        title: 'common.developing'.tr,
        description: 'common.developingDesc'.trParams({'name': name}),
      ),
    );
  }
}
