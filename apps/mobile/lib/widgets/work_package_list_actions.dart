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
          waitDuration: const Duration(milliseconds: 500),
          showDuration: const Duration(seconds: 2),
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
/// Pro değilse Görünüm, Filtre ve Kolonlar ikonlarında "Pro" rozeti gösterilir; tıklanınca [onProRequired] çağrılır.
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
    this.isPro = true,
    this.onProRequired,
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
  /// Pro kullanıcı değilse Görünüm/Filtre/Kolonlar ikonlarında Pro rozeti gösterilir ve tıklanınca [onProRequired] çağrılır.
  final bool isPro;
  /// Pro değilken kullanıcı Görünüm/Filtre/Kolonlar'a tıkladığında çağrılır (örn. Pro yükselt ekranına yönlendirme).
  final VoidCallback? onProRequired;

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
      bool showProBadge = false,
    }) {
      final fg = highlight ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant;
      Widget iconWidget = Icon(icon, size: 22, color: fg);
      if (showProBadge) {
        iconWidget = Badge(
          label: Icon(
            Icons.star_rounded,
            size: 12,
            color: theme.colorScheme.onPrimary,
          ),
          backgroundColor: theme.colorScheme.primary,
          smallSize: 18,
          child: iconWidget,
        );
      }
      return Tooltip(
        message: tooltip,
        waitDuration: const Duration(milliseconds: 500),
        showDuration: const Duration(seconds: 2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: iconWidget,
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
          child:           iconAction(
            icon: Icons.chevron_left_rounded,
            tooltip: 'Görünüm, sırala, filtre menüsünü aç',
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
              tooltip: 'Görünüm menüsünü gizle',
              onPressed: onToggleCollapsed,
            ),
            const Divider(height: 1),
            iconAction(
              icon: Icons.view_module_rounded,
              tooltip: isPro ? 'Kayıtlı görünüm (sorgu) seç' : 'Kayıtlı görünüm Pro\'da',
              showProBadge: !isPro,
              onPressed: isPro ? () => onOpenViews() : (onProRequired ?? () {}),
            ),
            if (showSort)
              iconAction(
                icon: Icons.sort_rounded,
                tooltip: 'Sıralama seçenekleri',
                onPressed: () => onOpenSort(),
              ),
            iconAction(
              icon: hasFilters ? Icons.filter_alt_rounded : Icons.tune_rounded,
              tooltip: isPro
                  ? (hasFilters ? 'Filtreler (aktif)' : 'Filtre ekle veya düzenle')
                  : 'Filtre ekleme Pro\'da',
              highlight: hasFilters && isPro,
              showProBadge: !isPro,
              onPressed: isPro ? () => onOpenFilters() : (onProRequired ?? () {}),
            ),
            iconAction(
              icon: Icons.view_agenda_rounded,
              tooltip: isPro ? 'Liste kolonlarını seç' : 'Kolon ayarları Pro\'da',
              showProBadge: !isPro,
              onPressed: isPro ? () => onOpenColumns() : (onProRequired ?? () {}),
            ),
            iconAction(
              icon: Icons.refresh_rounded,
              tooltip: 'Listeyi yenile',
              onPressed: () => onRefresh(),
            ),
          ],
        ),
      ),
    );
  }
}
