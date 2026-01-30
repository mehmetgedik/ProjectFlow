import 'package:flutter/material.dart';

import '../models/time_entry.dart';
import '../models/work_package.dart';
import '../state/time_tracking_prefs.dart';
import '../utils/date_formatters.dart';
import '../utils/haptic.dart';
import '../utils/snackbar_helpers.dart';
import 'letter_avatar.dart';
import 'time_tracking_entry_detail_sheet.dart';

/// Zaman takibi için özel tablo/liste bileşeni.
/// Kolonlar, gruplama, grup başlıklarını aç/kapa ve satır tıklanınca detay sheet sunar.
class TimeTrackingDataTable extends StatefulWidget {
  final List<TimeEntry> entries;
  final List<String> columnIds;
  final TimeTrackingGroupBy groupBy;
  /// Profil resimleri için (kullanıcı kolonu açıkken sol ikonda avatar).
  final String? instanceApiBaseUrl;
  final Map<String, String>? authHeadersForAvatars;
  final void Function(TimeEntry)? onEntryTap;
  final Widget Function(TimeEntry)? trailingBuilder;

  const TimeTrackingDataTable({
    super.key,
    required this.entries,
    required this.columnIds,
    required this.groupBy,
    this.instanceApiBaseUrl,
    this.authHeadersForAvatars,
    this.onEntryTap,
    this.trailingBuilder,
  });

  @override
  State<TimeTrackingDataTable> createState() => _TimeTrackingDataTableState();
}

class _TimeTrackingDataTableState extends State<TimeTrackingDataTable> {
  /// Kapalı grupların anahtarları (tıklanınca açılır/kapanır).
  final Set<String> _collapsedGroupKeys = <String>{};

  String _formatMonth(DateTime d) {
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return '${months[d.month - 1]} ${d.year}';
  }

  DateTime _weekStart(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  String _cellText(TimeEntry e, String colId) {
    switch (colId) {
      case 'date':
        return DateFormatters.formatDate(e.spentOn);
      case 'hours':
        return '${e.hours.toStringAsFixed(2)} s';
      case 'work_package':
        if (e.workPackageSubject != null && e.workPackageSubject!.trim().isNotEmpty) {
          return e.workPackageSubject!.trim();
        }
        return '—';
      case 'comment':
        return e.comment ?? '—';
      case 'activity':
        return e.activityName ?? '—';
      case 'user':
        return e.userName ?? '—';
      default:
        return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.entries.isEmpty) {
      return Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.schedule,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'Zaman kaydı yok.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Kolonlar menüsünden "İş" ekleyebilirsiniz.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    switch (widget.groupBy) {
      case TimeTrackingGroupBy.none:
        return _buildFlatTable(context, theme, widget.entries);
      case TimeTrackingGroupBy.day:
        return _buildGroupedByDay(context, theme);
      case TimeTrackingGroupBy.week:
        return _buildGroupedByWeek(context, theme);
      case TimeTrackingGroupBy.month:
        return _buildGroupedByMonth(context, theme);
      case TimeTrackingGroupBy.workPackage:
        return _buildGroupedByWorkPackage(context, theme);
    }
  }

  Widget _buildFlatTable(
    BuildContext context,
    ThemeData theme,
    List<TimeEntry> list,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final e = list[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildEntryCard(context, theme, e),
        );
      },
    );
  }

  Widget _buildGroupedByDay(BuildContext context, ThemeData theme) {
    final byDay = <DateTime, List<TimeEntry>>{};
    for (final e in widget.entries) {
      final key = DateTime(e.spentOn.year, e.spentOn.month, e.spentOn.day);
      byDay.putIfAbsent(key, () => []).add(e);
    }
    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: days.map((day) {
        final items = byDay[day]!;
        final total = items.fold(0.0, (s, e) => s + e.hours);
        final groupKey = 'd_${day.year}_${day.month}_${day.day}';
        final collapsed = _collapsedGroupKeys.contains(groupKey);
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _groupHeader(
                theme,
                Icons.today,
                DateFormatters.formatDate(day),
                total,
                collapsed,
                () {
                  lightImpact();
                  setState(() {
                    if (_collapsedGroupKeys.contains(groupKey)) {
                      _collapsedGroupKeys.remove(groupKey);
                    } else {
                      _collapsedGroupKeys.add(groupKey);
                    }
                  });
                },
              ),
              if (!collapsed) ...items.map((e) => _buildEntryCard(context, theme, e)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGroupedByWeek(BuildContext context, ThemeData theme) {
    final byWeek = <DateTime, List<TimeEntry>>{};
    for (final e in widget.entries) {
      final key = _weekStart(e.spentOn);
      byWeek.putIfAbsent(key, () => []).add(e);
    }
    final weeks = byWeek.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: weeks.map((weekStart) {
        final items = byWeek[weekStart]!;
        final total = items.fold(0.0, (s, e) => s + e.hours);
        final weekEnd = weekStart.add(const Duration(days: 6));
        final label = '${DateFormatters.formatDate(weekStart)} – ${DateFormatters.formatDate(weekEnd)}';
        final groupKey = 'w_${weekStart.millisecondsSinceEpoch}';
        final collapsed = _collapsedGroupKeys.contains(groupKey);
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _groupHeader(
                theme,
                Icons.date_range,
                label,
                total,
                collapsed,
                () {
                  lightImpact();
                  setState(() {
                    if (_collapsedGroupKeys.contains(groupKey)) {
                      _collapsedGroupKeys.remove(groupKey);
                    } else {
                      _collapsedGroupKeys.add(groupKey);
                    }
                  });
                },
              ),
              if (!collapsed) ...items.map((e) => _buildEntryCard(context, theme, e)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGroupedByMonth(BuildContext context, ThemeData theme) {
    final byMonth = <DateTime, List<TimeEntry>>{};
    for (final e in widget.entries) {
      final key = DateTime(e.spentOn.year, e.spentOn.month, 1);
      byMonth.putIfAbsent(key, () => []).add(e);
    }
    final months = byMonth.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: months.map((monthStart) {
        final items = byMonth[monthStart]!;
        final total = items.fold(0.0, (s, e) => s + e.hours);
        final groupKey = 'm_${monthStart.year}_${monthStart.month}';
        final collapsed = _collapsedGroupKeys.contains(groupKey);
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _groupHeader(
                theme,
                Icons.calendar_month,
                _formatMonth(monthStart),
                total,
                collapsed,
                () {
                  lightImpact();
                  setState(() {
                    if (_collapsedGroupKeys.contains(groupKey)) {
                      _collapsedGroupKeys.remove(groupKey);
                    } else {
                      _collapsedGroupKeys.add(groupKey);
                    }
                  });
                },
              ),
              if (!collapsed) ...items.map((e) => _buildEntryCard(context, theme, e)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGroupedByWorkPackage(BuildContext context, ThemeData theme) {
    final byWp = <String, List<TimeEntry>>{};
    for (final e in widget.entries) {
      final key = e.workPackageId != null
          ? '${e.workPackageId}|${e.workPackageSubject ?? ''}'
          : '—';
      byWp.putIfAbsent(key, () => []).add(e);
    }
    final keys = byWp.keys.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: keys.map((wpKey) {
        final items = byWp[wpKey]!;
        final total = items.fold(0.0, (s, e) => s + e.hours);
        final label = wpKey == '—' ? 'İş belirtilmemiş' : (items.first.workPackageSubject?.trim().isNotEmpty == true ? items.first.workPackageSubject!.trim() : '—');
        final groupKey = 'wp_$wpKey';
        final collapsed = _collapsedGroupKeys.contains(groupKey);
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _groupHeader(
                theme,
                Icons.work,
                label,
                total,
                collapsed,
                () {
                  lightImpact();
                  setState(() {
                    if (_collapsedGroupKeys.contains(groupKey)) {
                      _collapsedGroupKeys.remove(groupKey);
                    } else {
                      _collapsedGroupKeys.add(groupKey);
                    }
                  });
                },
              ),
              if (!collapsed) ...items.map((e) => _buildEntryCard(context, theme, e)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _groupHeader(
    ThemeData theme,
    IconData icon,
    String title,
    double totalHours,
    bool collapsed,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Row(
            children: [
              Icon(
                collapsed ? Icons.expand_more : Icons.expand_less,
                size: 24,
                color: theme.colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 6),
              Icon(icon, size: 22, color: theme.colorScheme.onPrimaryContainer),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${totalHours.toStringAsFixed(1)} s',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Kısaltılmış metin; [maxLen] karakterden uzunsa sonuna '…' eklenir.
  static String _shorten(String text, int maxLen) {
    if (text.length <= maxLen) return text;
    return '${text.substring(0, maxLen)}…';
  }

  /// Zaman kaydı satırı: saat · (kolon ayarı) tarih · (kolon ayarı) kategori · (kolon ayarı) iş başlığı. Tarih ve iş başlığı kolon ayarına göre.
  Widget _buildEntryCard(BuildContext context, ThemeData theme, TimeEntry e) {
    final showDate = widget.columnIds.contains('date');
    final showActivity = widget.columnIds.contains('activity');
    final showWorkPackage = widget.columnIds.contains('work_package');
    final showUser = widget.columnIds.contains('user');
    final dateText = _cellText(e, 'date');
    final activityText = e.activityName ?? '—';
    final hasActivity = showActivity && activityText != '—' && activityText.isNotEmpty;
    final workPackageText = _cellText(e, 'work_package');
    final hasWorkPackage = showWorkPackage && (workPackageText != '—' || (e.workPackageId != null && (e.workPackageSubject == null || e.workPackageSubject!.trim().isEmpty)));
    final workTitleFull = workPackageText != '—' ? workPackageText : (e.workPackageId != null ? 'İş #${e.workPackageId}' : null);
    const int workTitleMaxLen = 32;
    final workTitleShort = hasWorkPackage ? _shorten(workPackageText, workTitleMaxLen) : '';

    final smallStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Material(
      color: theme.colorScheme.surface,
      child: InkWell(
        onTap: widget.onEntryTap != null
            ? () {
                lightImpact();
                widget.onEntryTap!(e);
              }
            : null,
        onLongPress: workTitleFull != null && workTitleFull.isNotEmpty
            ? () {
                lightImpact();
                showAppSnackBar(context, workTitleFull, duration: const Duration(seconds: 3));
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: showUser && (e.userName ?? '').trim().isNotEmpty
                    ? LetterAvatar(
                        displayName: e.userName,
                        imageUrl: widget.instanceApiBaseUrl != null &&
                                e.userId != null &&
                                e.userId!.isNotEmpty
                            ? '${widget.instanceApiBaseUrl!.replaceAll(RegExp(r'/+$'), '')}/users/${e.userId}/avatar'
                            : null,
                        imageHeaders: widget.authHeadersForAvatars,
                        size: 28,
                      )
                    : Icon(
                        Icons.schedule,
                        size: 22,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _cellText(e, 'hours'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    if (showDate) ...[
                      _dot(theme),
                      Flexible(
                        child: Text(
                          dateText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    if (hasActivity) ...[
                      _dot(theme),
                      Flexible(
                        child: Text(
                          activityText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: smallStyle ?? theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                    if (hasWorkPackage) ...[
                      _dot(theme),
                      Expanded(
                        child: Tooltip(
                          message: workTitleFull ?? workPackageText,
                          preferBelow: false,
                          child: Text(
                            workTitleShort,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: smallStyle ?? theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.onEntryTap != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        ' · ',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Zaman kaydı satırına tıklanınca açılan detay bottom sheet.
/// Hangi işe ait olduğunu gösterir, "İşe git" ile WP detayına gider.
void showTimeEntryDetailSheet({
  required BuildContext context,
  required TimeEntry entry,
  void Function(WorkPackage)? onOpenWorkPackage,
  void Function()? onDeleted,
  void Function(TimeEntry)? onEditRequested,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => TimeTrackingEntryDetailSheet(
      entry: entry,
      onOpenWorkPackage: onOpenWorkPackage,
      onDeleted: onDeleted,
      onEditRequested: onEditRequested,
    ),
  );
}
