import 'package:flutter/material.dart';

/// Filtre çubuğunda kullanılan ikonlu buton (seçili/seçili değil).
class FilterIconButton extends StatelessWidget {
  const FilterIconButton({
    super.key,
    required this.icon,
    required this.selectedIcon,
    required this.tooltip,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String tooltip;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(
              selected ? selectedIcon : icon,
              size: 22,
              color: selected
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

/// İş listesi ekranında sağ tarafta sticky görünüm/sırala/filtre/kolonlar/yenile aksiyonları.
class StickySideActions extends StatelessWidget {
  const StickySideActions({
    super.key,
    required this.collapsed,
    required this.onToggleCollapsed,
    required this.showSort,
    required this.hasFilters,
    required this.onOpenViews,
    required this.onOpenSort,
    required this.onOpenFilters,
    required this.onOpenColumns,
    required this.onRefresh,
  });

  final bool collapsed;
  final VoidCallback onToggleCollapsed;
  final bool showSort;
  final bool hasFilters;
  final Future<void> Function() onOpenViews;
  final Future<void> Function() onOpenSort;
  final Future<void> Function() onOpenFilters;
  final Future<void> Function() onOpenColumns;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.9);
    final border = theme.colorScheme.outlineVariant.withValues(alpha: 0.5);

    Widget iconAction({
      required IconData icon,
      required String tooltip,
      required VoidCallback onPressed,
      bool highlight = false,
    }) {
      final fg = highlight ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant;
      return Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(icon, size: 22, color: fg),
            ),
          ),
        ),
      );
    }

    if (collapsed) {
      return Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: border),
          ),
          child: iconAction(
            icon: Icons.chevron_left_rounded,
            tooltip: 'Menüyü aç',
            onPressed: onToggleCollapsed,
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconAction(
              icon: Icons.chevron_right_rounded,
              tooltip: 'Menüyü gizle',
              onPressed: onToggleCollapsed,
            ),
            const Divider(height: 1),
            iconAction(
              icon: Icons.view_module_rounded,
              tooltip: 'Görünüm seç',
              onPressed: () => onOpenViews(),
            ),
            if (showSort)
              iconAction(
                icon: Icons.sort_rounded,
                tooltip: 'Sırala',
                onPressed: () => onOpenSort(),
              ),
            iconAction(
              icon: hasFilters ? Icons.filter_alt_rounded : Icons.tune_rounded,
              tooltip: 'Filtreler',
              highlight: hasFilters,
              onPressed: () => onOpenFilters(),
            ),
            iconAction(
              icon: Icons.view_agenda_rounded,
              tooltip: 'Kolonlar',
              onPressed: () => onOpenColumns(),
            ),
            iconAction(
              icon: Icons.refresh_rounded,
              tooltip: 'Yenile',
              onPressed: () => onRefresh(),
            ),
          ],
        ),
      ),
    );
  }
}
