import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Một ô trong [PhotoGrid]: ảnh (hoặc biểu tượng tệp) + nút xoá nhỏ ở góc.
class PhotoGridTile {
  const PhotoGridTile({
    this.image,
    this.fileLabel,
    this.onTap,
    this.onRemove,
    this.removeTooltip,
  });

  /// Ảnh hiển thị; null → ô biểu tượng tệp kèm [fileLabel].
  final ImageProvider? image;
  final String? fileLabel;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final String? removeTooltip;
}

/// Lưới ảnh/tệp bo góc; có [onAdd] thì thêm ô "+" ở cuối lưới.
class PhotoGrid extends StatelessWidget {
  const PhotoGrid({
    super.key,
    required this.tiles,
    this.onAdd,
    this.addLabel,
    this.size = 96,
  });

  final List<PhotoGridTile> tiles;
  final VoidCallback? onAdd;
  final String? addLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final t in tiles) _Tile(tile: t, size: size),
        if (onAdd != null) _AddTile(size: size, label: addLabel, onTap: onAdd!),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.tile, required this.size});

  final PhotoGridTile tile;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Material(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: tile.onTap,
                child: tile.image != null
                    ? Image(
                        image: tile.image!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 28,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.insert_drive_file_outlined,
                              size: 28,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            if (tile.fileLabel != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xs,
                                ),
                                child: Text(
                                  tile.fileLabel!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelSmall,
                                ),
                              ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
          if (tile.onRemove != null)
            Positioned(
              top: -6,
              right: -6,
              child: Material(
                color: theme.colorScheme.surface,
                shape: const CircleBorder(),
                elevation: 2,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: tile.onRemove,
                  child: Tooltip(
                    message:
                        tile.removeTooltip ??
                        MaterialLocalizations.of(context).deleteButtonTooltip,
                    child: SizedBox(
                      width: 26,
                      height: 26,
                      child: Icon(
                        Icons.close,
                        size: 15,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.size, required this.onTap, this.label});

  final double size;
  final VoidCallback onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: context.cardBorder),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_a_photo_outlined,
                  color: theme.colorScheme.primary,
                ),
                if (label != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    child: Text(
                      label!,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
