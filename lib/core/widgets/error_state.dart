import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../errors/api_error.dart';
import 'empty_state.dart';

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: LucideIcons.circleAlert,
      title: 'common.error'.tr,
      description: ApiError.messageFor(error),
      action: onRetry == null
          ? null
          : OutlinedButton(onPressed: onRetry, child: Text('common.retry'.tr)),
    );
  }
}
