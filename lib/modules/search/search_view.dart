import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_list.dart';
import 'search_controller.dart';

/// Tìm kiếm toàn cục: thiết bị, vật tư, sửa chữa, phiếu yêu cầu.
class SearchView extends GetView<GlobalSearchController> {
  const SearchView({super.key});

  static const _icons = {
    'equipment': Icons.biotech_outlined,
    'supplies': Icons.inventory_2_outlined,
    'repairs': Icons.build_outlined,
    'requests': Icons.description_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: controller.query,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: controller.onQueryChanged,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'search.hint'.tr,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'common.clear'.tr,
            icon: const Icon(Icons.close),
            onPressed: () {
              controller.query.clear();
              controller.onQueryChanged('');
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.loading.value && controller.groups.isEmpty) {
          return const LoadingList();
        }
        if (controller.searched.value &&
            controller.groups.isEmpty &&
            controller.error.value != null) {
          return ErrorState(
            error: controller.error.value!,
            onRetry: () => controller.search(controller.query.text),
          );
        }
        if (controller.searched.value && controller.groups.isEmpty) {
          return EmptyState(
            icon: Icons.search_off,
            title: 'search.noResult'.tr,
          );
        }
        if (!controller.searched.value) {
          return EmptyState(icon: Icons.search, title: 'search.minChars'.tr);
        }
        return ListView(
          children: [
            for (final g in controller.groups) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xs,
                ),
                child: Text(
                  'search.group.${g.key}'.tr,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              for (final hit in g.hits)
                ListTile(
                  leading: Icon(_icons[g.key] ?? Icons.search),
                  title: Text(hit.title),
                  subtitle: hit.subtitle.isEmpty ? null : Text(hit.subtitle),
                  onTap: () => controller.open(hit),
                ),
            ],
          ],
        );
      }),
    );
  }
}
