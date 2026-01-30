import 'package:flutter/material.dart';

/// İş listesi ve zaman ekleme formunda kullanılmak üzere durum/tür renk ve ikonları (web parity).
class WorkPackageVisuals {
  WorkPackageVisuals._();

  /// Duruma göre renk ve ikon.
  static (Color bg, Color fg, IconData icon) statusVisuals(BuildContext context, String status) {
    final theme = Theme.of(context);
    final s = status.toLowerCase();
    if (s.contains('yeni') || s.contains('new')) {
      return (theme.colorScheme.primaryContainer, theme.colorScheme.onPrimaryContainer, Icons.fiber_new_rounded);
    }
    if (s.contains('devam') || s.contains('progress') || s.contains('in progress')) {
      return (theme.colorScheme.tertiaryContainer, theme.colorScheme.onTertiaryContainer, Icons.play_circle_rounded);
    }
    if (s.contains('bekle') || s.contains('on hold') || s.contains('pending')) {
      return (theme.colorScheme.surfaceContainerHighest, theme.colorScheme.onSurfaceVariant, Icons.pause_circle_rounded);
    }
    if (s.contains('tamam') || s.contains('closed') || s.contains('done') || s.contains('çözüldü')) {
      return (theme.colorScheme.secondaryContainer, theme.colorScheme.onSecondaryContainer, Icons.check_circle_rounded);
    }
    if (s.contains('iptal') || s.contains('cancel')) {
      return (theme.colorScheme.errorContainer, theme.colorScheme.onErrorContainer, Icons.cancel_rounded);
    }
    return (theme.colorScheme.primaryContainer, theme.colorScheme.onPrimaryContainer, Icons.radio_button_unchecked_rounded);
  }

  /// İş tipi için renk ve ikon.
  static (Color bg, Color fg, IconData icon) typeVisuals(BuildContext context, String type) {
    final theme = Theme.of(context);
    final t = type.toLowerCase();
    if (t.contains('bug') || t.contains('hata')) {
      return (theme.colorScheme.errorContainer, theme.colorScheme.onErrorContainer, Icons.bug_report_rounded);
    }
    if (t.contains('task') || t.contains('görev')) {
      return (theme.colorScheme.secondaryContainer, theme.colorScheme.onSecondaryContainer, Icons.task_alt_rounded);
    }
    if (t.contains('feature') || t.contains('özellik')) {
      return (theme.colorScheme.tertiaryContainer, theme.colorScheme.onTertiaryContainer, Icons.auto_awesome_rounded);
    }
    if (t.contains('milestone') || t.contains('kilometre')) {
      return (theme.colorScheme.primaryContainer, theme.colorScheme.onPrimaryContainer, Icons.flag_rounded);
    }
    return (theme.colorScheme.surfaceContainerHighest, theme.colorScheme.onSurfaceVariant, Icons.label_rounded);
  }

  /// Durum etiketi (chip) widget.
  static Widget statusChip(BuildContext context, String status) {
    final (bg, fg, icon) = statusVisuals(context, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            status,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
          ),
        ],
      ),
    );
  }

  /// Tür etiketi (chip) widget.
  static Widget typeChip(BuildContext context, String type) {
    final (bg, fg, icon) = typeVisuals(context, type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            type,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
          ),
        ],
      ),
    );
  }

  /// Öncelik için renk ve ikon.
  static (Color bg, Color fg, IconData icon) priorityVisuals(BuildContext context, String priority) {
    final theme = Theme.of(context);
    final p = (priority.isEmpty ? '' : priority).toLowerCase();
    if (p.contains('acil') || p.contains('urgent') || p.contains('yüksek') || p.contains('high') || p.contains('critical')) {
      return (theme.colorScheme.errorContainer, theme.colorScheme.onErrorContainer, Icons.priority_high_rounded);
    }
    if (p.contains('orta') || p.contains('medium') || p.contains('normal')) {
      return (theme.colorScheme.tertiaryContainer, theme.colorScheme.onTertiaryContainer, Icons.remove_circle_outline_rounded);
    }
    if (p.contains('düşük') || p.contains('low')) {
      return (theme.colorScheme.surfaceContainerHighest, theme.colorScheme.onSurfaceVariant, Icons.low_priority_rounded);
    }
    return (theme.colorScheme.surfaceContainerHighest, theme.colorScheme.onSurfaceVariant, Icons.flag_rounded);
  }

  /// Öncelik etiketi (chip) widget — renk ve ikon ile.
  static Widget priorityChip(BuildContext context, String priority) {
    final (bg, fg, icon) = priorityVisuals(context, priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            priority,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
          ),
        ],
      ),
    );
  }

  /// API'den gelen hex rengi Color'a çevirir (#rrggbb veya rrggbb; 8 karakter için aa öne eklenir).
  static Color? colorFromHex(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    String h = hex.startsWith('#') ? hex.substring(1) : hex;
    if (h.length == 6) h = 'FF$h';
    if (h.length != 8) return null;
    final n = int.tryParse(h, radix: 16);
    return n != null ? Color(n) : null;
  }

  /// Arka plan rengine göre okunabilir metin rengi (siyah/beyaz).
  static Color contrastOn(Color bg) =>
      bg.computeLuminance() > 0.4 ? const Color(0xFF000000) : const Color(0xFFFFFFFF);

  /// API map (name/id/color) ile durum görseli; color varsa kullanır, yoksa tema ile statusVisuals.
  static (Color bg, Color fg, IconData icon) statusVisualsFromMap(
      BuildContext context, Map<String, String> s) {
    final name = s['name'] ?? s['id'] ?? '';
    final apiColor = colorFromHex(s['color']);
    if (apiColor != null) {
      final (_, fg, icon) = statusVisuals(context, name);
      return (apiColor, contrastOn(apiColor), icon);
    }
    return statusVisuals(context, name);
  }

  /// API map (name/id/color) ile tür görseli; color varsa kullanır, yoksa tema ile typeVisuals.
  static (Color bg, Color fg, IconData icon) typeVisualsFromMap(
      BuildContext context, Map<String, String> t) {
    final name = t['name'] ?? t['id'] ?? '';
    final apiColor = colorFromHex(t['color']);
    if (apiColor != null) {
      final (_, fg, icon) = typeVisuals(context, name);
      return (apiColor, contrastOn(apiColor), icon);
    }
    return typeVisuals(context, name);
  }
}
