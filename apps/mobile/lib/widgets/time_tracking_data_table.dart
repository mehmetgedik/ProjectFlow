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

  IconData _columnIcon(String colId) {
    switch (colId) {
      case 'date':
        return Icons.calendar_today;
      case 'hours':
        return Icons.schedule;
      case 'work_package':
        return Icons.work;
      case 'comment':
        return Icons.comment_outlined;
      case 'activity':
        return Icons.category_outlined;
      case 'user':
        return Icons.person_outline;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (entries.isEmpty) {
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
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
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
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
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
          elevation: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _groupHeader(theme, Icons.today, _formatDate(day), total),
              ...items.map((e) => _buildEntryCard(context, theme, e)),
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
          elevation: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _groupHeader(theme, Icons.date_range, label, total),
              ...items.map((e) => _buildEntryCard(context, theme, e)),
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
          elevation: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _groupHeader(theme, Icons.calendar_month, _formatMonth(monthStart), total),
              ...items.map((e) => _buildEntryCard(context, theme, e)),
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
          elevation: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _groupHeader(theme, Icons.work, label, total),
              ...items.map((e) => _buildEntryCard(context, theme, e)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _groupHeader(ThemeData theme, IconData icon, String title, double totalHours) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
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
              color: theme.colorScheme.primary.withOpacity(0.2),
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
    );
  }

  /// Zaman kaydı satırı: solda saat/tarih, sağda kategori (aktivite). Yorum ve iş detayı tıklanınca sheet'te.
  Widget _buildEntryCard(BuildContext context, ThemeData theme, TimeEntry e) {
    final activityLabel = e.activityName ?? '—';
    final hasActivity = activityLabel != '—' && activityLabel.isNotEmpty;

    return Material(
      color: theme.colorScheme.surface,
      child: InkWell(
        onTap: onEntryTap != null
            ? () {
                lightImpact();
                onEntryTap!(e);
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.schedule,
                  size: 24,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _cellText(e, 'hours'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _cellText(e, 'date'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasActivity)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 16,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 120),
                        child: Text(
                          activityLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (onEntryTap != null)
                Icon(
                  Icons.chevron_right,
                  size: 22,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
            ],
          ),
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
