import 'package:flutter/material.dart';

class BathToolbarItemData<T extends Object> {
  final T data;
  final String label;
  final Color color;
  final bool enabled;
  final int resetNonce;
  final Widget Function(double size, bool enabled) iconBuilder;
  final Widget Function(double size) feedbackBuilder;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnded;

  const BathToolbarItemData({
    required this.data,
    required this.label,
    required this.color,
    required this.enabled,
    required this.resetNonce,
    required this.iconBuilder,
    required this.feedbackBuilder,
    required this.onDragStarted,
    required this.onDragEnded,
  });
}

class BathToolbarWidget<T extends Object> extends StatelessWidget {
  final double width;
  final List<BathToolbarItemData<T>> items;

  const BathToolbarWidget({
    super.key,
    required this.width,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final compactLayout = width < 340;
    final iconSize = compactLayout ? 20.0 : 22.0;
    final labelSize = compactLayout ? 7.4 : 8.0;
    final verticalPadding = compactLayout ? 8.0 : 10.0;

    return Container(
      width: width,
      padding: EdgeInsets.symmetric(
        horizontal: compactLayout ? 10 : 12,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF6C8FA3).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: items
            .map(
              (item) => Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: compactLayout ? 2 : 4,
                  ),
                  child: _BathToolbarItem<T>(
                    item: item,
                    iconSize: iconSize,
                    labelSize: labelSize,
                    compactLayout: compactLayout,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _BathToolbarItem<T extends Object> extends StatelessWidget {
  final BathToolbarItemData<T> item;
  final double iconSize;
  final double labelSize;
  final bool compactLayout;

  const _BathToolbarItem({
    required this.item,
    required this.iconSize,
    required this.labelSize,
    required this.compactLayout,
  });

  @override
  Widget build(BuildContext context) {
    Widget tile({required double opacity}) {
      return Opacity(
        opacity: opacity,
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: compactLayout ? 8 : 10,
            horizontal: 4,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.color.withValues(alpha: 0.78),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              item.iconBuilder(iconSize * 2.2, item.enabled),
              SizedBox(height: compactLayout ? 2 : 4),
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: labelSize,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF4A6472),
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!item.enabled) {
      return tile(opacity: 0.6);
    }

    return Draggable<T>(
      key: ValueKey('${item.label}-${item.resetNonce}'),
      data: item.data,
      rootOverlay: true,
      onDragStarted: item.onDragStarted,
      onDragEnd: (_) => item.onDragEnded(),
      onDraggableCanceled: (_, _) => item.onDragEnded(),
      onDragCompleted: item.onDragEnded,
      feedback: Material(
        color: Colors.transparent,
        child: IgnorePointer(
          child: item.feedbackBuilder(compactLayout ? 54 : 60),
        ),
      ),
      childWhenDragging: tile(opacity: 0.35),
      child: tile(opacity: 1.0),
    );
  }
}
