import 'package:flutter/material.dart';
import 'package:flutter_gantt/flutter_gantt.dart';

import '../models/work_package.dart';
import '../screens/work_package_detail_screen.dart';
import '../utils/haptic.dart';

/// Gantt tarih kaynağı: çubukların eksende nereye göre konumlanacağı.
enum GanttDateSource {
  /// Başlangıç–bitiş tarihi (startDate / dueDate). İkisi de olan işler gösterilir.
  startDue,
  /// Son güncelleme tarihi (updatedAt). O gün tek günlük çubuk.
  updatedAt,
}

/// Gantt görünümü: [items] içinden [dateSource]a göre işleri gösterir.
/// Çubuğa tıklanınca [onTap] çağrılır; verilmezse detay ekranına gider.
class WorkPackagesGantt extends StatelessWidget {
  final List<WorkPackage> items;
  final GanttDateSource dateSource;
  final void Function(WorkPackage wp)? onTap;
  final Future<void> Function()? onRefresh;

  const WorkPackagesGantt({
    super.key,
    required this.items,
    this.dateSource = GanttDateSource.startDue,
    this.onTap,
    this.onRefresh,
  });

  /// Tarih atanmış işler (startDate ve dueDate var, start <= end).
  static List<WorkPackage> _datedItems(List<WorkPackage> items) {
    return items.where((wp) {
      final s = wp.startDate;
      final d = wp.dueDate;
      if (s == null || d == null) return false;
      final start = DateTime(s.year, s.month, s.day);
      final end = DateTime(d.year, d.month, d.day);
      return !start.isAfter(end);
    }).toList();
  }

  /// updatedAt olan işler (güncelleme tarihine göre tek günlük çubuk).
  static List<WorkPackage> _updatedItems(List<WorkPackage> items) {
    return items.where((wp) => wp.updatedAt != null).toList();
  }

  static List<GanttActivity> _toActivitiesStartDue(
    List<WorkPackage> dated,
    Map<String, WorkPackage> idToWp,
    void Function(WorkPackage wp) onTap,
    Color barColor,
  ) {
    return dated.map((wp) {
      final s = wp.startDate!;
      final d = wp.dueDate!;
      var start = DateTime(s.year, s.month, s.day);
      var end = DateTime(d.year, d.month, d.day);
      if (start.isAfter(end)) {
        final t = start;
        start = end;
        end = t;
      }
      return GanttActivity(
        key: wp.id,
        start: start,
        end: end,
        title: wp.subject,
        color: barColor,
        onCellTap: (a) {
          lightImpact();
          final x = idToWp[a.key];
          if (x != null) onTap(x);
        },
      );
    }).toList();
  }

  static List<GanttActivity> _toActivitiesUpdatedAt(
    List<WorkPackage> list,
    Map<String, WorkPackage> idToWp,
    void Function(WorkPackage wp) onTap,
    Color barColor,
  ) {
    return list.map((wp) {
      final u = wp.updatedAt!;
      final day = DateTime(u.year, u.month, u.day);
      return GanttActivity(
        key: wp.id,
        start: day,
        end: day,
        title: wp.subject,
        color: barColor,
        onCellTap: (a) {
          lightImpact();
          final x = idToWp[a.key];
          if (x != null) onTap(x);
        },
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = dateSource == GanttDateSource.startDue
        ? _datedItems(items)
        : _updatedItems(items);
    if (dateSource == GanttDateSource.updatedAt) {
      list.sort((a, b) => (a.updatedAt ?? DateTime(0)).compareTo(b.updatedAt ?? DateTime(0)));
    }
    final idToWp = {for (final w in list) w.id: w};
    final barColor = Theme.of(context).colorScheme.primary;

    void handleTap(WorkPackage wp) {
      if (onTap != null) {
        onTap!(wp);
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WorkPackageDetailScreen(workPackage: wp),
        ),
      );
    }

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.date_range_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 12),
              Text(
                _emptyMessage(context),
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

    final activities = dateSource == GanttDateSource.startDue
        ? _toActivitiesStartDue(list, idToWp, handleTap, barColor)
        : _toActivitiesUpdatedAt(list, idToWp, handleTap, barColor);
    var initialDate = DateTime.now();
    if (dateSource == GanttDateSource.startDue) {
      final starts = list.map((w) => w.startDate!).toList();
      if (starts.isNotEmpty) {
        starts.sort((a, b) => a.compareTo(b));
        initialDate = DateTime(starts.first.year, starts.first.month, starts.first.day);
      }
    } else {
      final ups = list.map((w) => w.updatedAt!).toList();
      if (ups.isNotEmpty) {
        ups.sort((a, b) => a.compareTo(b));
        initialDate = DateTime(ups.first.year, ups.first.month, ups.first.day);
      }
    }

    const monthTr = ['', 'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];

    return Gantt(
      startDate: initialDate,
      activities: activities,
      enableDraggable: false,
      monthToText: (_, d) => '${monthTr[d.month]} ${d.year}',
    );
  }

  String _emptyMessage(BuildContext context) {
    if (items.isEmpty) return 'Gösterilecek iş yok.';
    switch (dateSource) {
      case GanttDateSource.startDue:
        return 'Tarih atanmış iş bulunamadı. Başlangıç ve bitiş tarihi olan işler Gantt\'ta görünür.';
      case GanttDateSource.updatedAt:
        return 'Güncelleme tarihi olan iş bulunamadı.';
    }
  }
}
