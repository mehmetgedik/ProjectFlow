import 'package:flutter/material.dart';
import 'package:flutter_gantt/flutter_gantt.dart';

import '../models/time_entry.dart';
import '../models/work_package.dart';
import '../screens/work_package_detail_screen.dart';
import '../utils/haptic.dart';

/// Zaman kayıtlarına göre Gantt: [entries] içinden WP bazlı min(spentOn)..max(spentOn) çubukları.
/// Çubuğa tıklanınca ilgili iş paketi detayına gider.
class TimeEntriesGantt extends StatelessWidget {
  final List<TimeEntry> entries;
  final Future<void> Function()? onRefresh;

  const TimeEntriesGantt({
    super.key,
    required this.entries,
    this.onRefresh,
  });

  /// workPackageId'ye göre grupla; her WP için min/max spentOn ve ilk görülen subject.
  static Map<String, ({DateTime start, DateTime end, String subject})> _groupByWp(
    List<TimeEntry> entries,
  ) {
    final map = <String, ({DateTime start, DateTime end, String subject})>{};
    for (final e in entries) {
      final id = e.workPackageId?.trim();
      if (id == null || id.isEmpty) continue;
      final day = DateTime(e.spentOn.year, e.spentOn.month, e.spentOn.day);
      final subj = e.workPackageSubject?.trim().isNotEmpty == true
          ? e.workPackageSubject!
          : '#$id';
      if (!map.containsKey(id)) {
        map[id] = (start: day, end: day, subject: subj);
      } else {
        final cur = map[id]!;
        final start = day.isBefore(cur.start) ? day : cur.start;
        final end = day.isAfter(cur.end) ? day : cur.end;
        map[id] = (start: start, end: end, subject: cur.subject);
      }
    }
    return map;
  }

  static List<GanttActivity> _toActivities(
    Map<String, ({DateTime start, DateTime end, String subject})> wpRanges,
    void Function(String wpId, String subject) onTap,
    Color barColor,
  ) {
    final list = wpRanges.entries.toList();
    list.sort((a, b) => a.value.start.compareTo(b.value.start));
    return list.map((e) {
      var start = e.value.start;
      var end = e.value.end;
      if (start.isAfter(end)) {
        final t = start;
        start = end;
        end = t;
      }
      final id = e.key;
      final subj = e.value.subject;
      return GanttActivity(
        key: id,
        start: start,
        end: end,
        title: subj,
        color: barColor,
        onCellTap: (_) {
          lightImpact();
          onTap(id, subj);
        },
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final wpRanges = _groupByWp(entries);
    final barColor = Theme.of(context).colorScheme.tertiary;

    void handleTap(String wpId, String subject) {
      final wp = WorkPackage(
        id: wpId,
        subject: subject,
        statusName: '-',
      );
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WorkPackageDetailScreen(workPackage: wp),
        ),
      );
    }

    if (wpRanges.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 12),
              Text(
                entries.isEmpty
                    ? 'Zaman kaydı yok.'
                    : 'İş paketine bağlı zaman kaydı bulunamadı. Zaman kaydı girilen işler Gantt\'ta görünür.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              if (onRefresh != null) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () async {
                    await onRefresh!();
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text('Yenile'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final activities = _toActivities(wpRanges, handleTap, barColor);
    final dates = wpRanges.values.expand((r) => [r.start, r.end]).toList();
    dates.sort((a, b) => a.compareTo(b));
    final initialDate = dates.isEmpty
        ? DateTime.now()
        : DateTime(dates.first.year, dates.first.month, dates.first.day);

    const monthTr = ['', 'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];

    return Gantt(
      startDate: initialDate,
      activities: activities,
      enableDraggable: false,
      monthToText: (_, d) => '${monthTr[d.month]} ${d.year}',
    );
  }
}
