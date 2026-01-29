import 'package:flutter/material.dart';

import '../models/time_entry.dart';
import '../models/work_package.dart';
import '../state/time_tracking_prefs.dart';
import '../utils/haptic.dart';
import 'time_tracking_entry_detail_sheet.dart';

/// Zaman takibi için özel tablo/liste bileşeni.
/// Kolonlar, gruplama ve satır tıklanınca detay sheet sunar.
class TimeTrackingDataTable extends StatelessWidget {
  final List<TimeEntry> entries;
  final List<String> columnIds;
  final TimeTrackingGroupBy groupBy;
  final void Function(TimeEntry)? onEntryTap;
  final Widget Function(TimeEntry)? trailingBuilder;

  const TimeTrackingDataTable({
    super.key,
    required this.entries,
    required this.columnIds,
    required this.groupBy,
    this.onEntryTap,
    this.trailingBuilder,
  });

  String _formatDate(DateTime d) {
    final dd = d.toLocal();
    return '${dd.day.toString().padLeft(2, '0')}.${dd.month.toString().padLeft(2, '0')}.${dd.year}';
  }

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
        return _formatDate(e.spentOn);
      case 'hours':
        return '${e.hours.toStringAsFixed(2)} s';
      case 'work_package':
        if (e.workPackageId == null) return '—';
        return e.workPackageSubject != null
            ? '#${e.workPackageId} · ${e.workPackageSubject}'
            : '#${e.workPackageId}';
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

  String _columnLabel(String colId) {
    switch (colId) {
      case 'date':
        return 'Tarih';
      case 'hours':
        return 'Saat';
      case 'work_package':
        return 'İş';
      case 'comment':
        return 'Açıklama';
      case 'activity':
        return 'Aktivite';
      case 'user':
        return 'Kullanıcı';
      default:
        return colId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (entries.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Zaman kaydı yok.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    switch (groupBy) {
      case TimeTrackingGroupBy.none:
        return _buildFlatTable(context, theme, entries);
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(
          theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        ),
        columns: [
          for (final colId in columnIds)
            DataColumn(
              label: Text(
                _columnLabel(colId),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const DataColumn(label: SizedBox.shrink()),
        ],
        rows: [
          for (final e in list)
            DataRow(
              cells: [
                for (final colId in columnIds)
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: Text(
                        _cellText(e, colId),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ),
                DataCell(
                  trailingBuilder?.call(e) ??
                      (onEntryTap != null
                          ? const Icon(Icons.chevron_right, size: 20)
                          : const SizedBox.shrink()),
                ),
              ],
              onSelectChanged: onEntryTap != null
                  ? (_) {
                      lightImpact();
                      onEntryTap!(e);
                    }
                  : null,
            ),
        ],
      ),
    );
  }

  Widget _buildGroupedByDay(BuildContext context, ThemeData theme) {
    final byDay = <DateTime, List<TimeEntry>>{};
    for (final e in entries) {
      final key = DateTime(e.spentOn.year, e.spentOn.month, e.spentOn.day);
      byDay.putIfAbsent(key, () => []).add(e);
    }
    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: days.map((day) {
        final items = byDay[day]!;
        final total = items.fold(0.0, (s, e) => s + e.hours);
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _groupHeader(theme, _formatDate(day), total),
              ...items.map((e) => _buildRow(context, theme, e)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGroupedByWeek(BuildContext context, ThemeData theme) {
    final byWeek = <DateTime, List<TimeEntry>>{};
    for (final e in entries) {
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
        final label = '${_formatDate(weekStart)} – ${_formatDate(weekEnd)}';
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _groupHeader(theme, label, total),
              ...items.map((e) => _buildRow(context, theme, e)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGroupedByMonth(BuildContext context, ThemeData theme) {
    final byMonth = <DateTime, List<TimeEntry>>{};
    for (final e in entries) {
      final key = DateTime(e.spentOn.year, e.spentOn.month, 1);
      byMonth.putIfAbsent(key, () => []).add(e);
    }
    final months = byMonth.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: months.map((monthStart) {
        final items = byMonth[monthStart]!;
        final total = items.fold(0.0, (s, e) => s + e.hours);
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _groupHeader(theme, _formatMonth(monthStart), total),
              ...items.map((e) => _buildRow(context, theme, e)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGroupedByWorkPackage(BuildContext context, ThemeData theme) {
    final byWp = <String, List<TimeEntry>>{};
    for (final e in entries) {
      final key = e.workPackageId != null
          ? '${e.workPackageId}|${e.workPackageSubject ?? ''}'
          : '—';
      byWp.putIfAbsent(key, () => []).add(e);
    }
    final keys = byWp.keys.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: keys.map((key) {
        final items = byWp[key]!;
        final total = items.fold(0.0, (s, e) => s + e.hours);
        final label = key == '—' ? 'İş belirtilmemiş' : (items.first.workPackageSubject ?? '#${items.first.workPackageId}');
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _groupHeader(theme, label, total),
              ...items.map((e) => _buildRow(context, theme, e)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _groupHeader(ThemeData theme, String title, double totalHours) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${totalHours.toStringAsFixed(1)} s',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, ThemeData theme, TimeEntry e) {
    final subtitleParts = <String>[];
    for (final colId in columnIds) {
      if (colId == 'hours' || colId == 'date') continue;
      final t = _cellText(e, colId);
      if (t != '—' && t.isNotEmpty) subtitleParts.add(t);
    }
    return ListTile(
      dense: true,
      title: Text(
        '${_cellText(e, 'hours')} · ${_cellText(e, 'date')}',
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitleParts.isEmpty
          ? null
          : Text(
              subtitleParts.join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
      trailing: onEntryTap != null
          ? (trailingBuilder?.call(e) ?? const Icon(Icons.chevron_right, size: 20))
          : trailingBuilder?.call(e),
      onTap: onEntryTap != null
          ? () {
              lightImpact();
              onEntryTap!(e);
            }
          : null,
    );
  }
}

/// Zaman kaydı satırına tıklanınca açılan detay bottom sheet.
/// Hangi işe ait olduğunu gösterir, "İşe git" ile WP detayına gider.
void showTimeEntryDetailSheet({
  required BuildContext context,
  required TimeEntry entry,
  void Function(WorkPackage)? onOpenWorkPackage,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => TimeTrackingEntryDetailSheet(
      entry: entry,
      onOpenWorkPackage: onOpenWorkPackage,
    ),
  );
}
