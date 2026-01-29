import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/openproject_client.dart';
import '../models/saved_query.dart';
import '../models/version.dart';
import '../models/work_package.dart';
import '../state/auth_state.dart';
import '../state/dashboard_prefs.dart';
import '../utils/error_messages.dart';
import '../utils/haptic.dart';
import '../widgets/letter_avatar.dart';
import '../widgets/projectflow_logo_button.dart';
import 'my_work_packages_screen.dart';
import 'work_package_detail_screen.dart';

/// Dashboard'da kullanılabilecek grafik türleri.
enum DashboardChartType {
  bar('Dikey çubuk'),
  horizontalBar('Yatay çubuk'),
  pie('Pasta'),
  donut('Halka'),
  timeSeries('Zaman (bitişe göre)');

  const DashboardChartType(this.label);
  final String label;
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  String? _error;
  List<WorkPackage> _items = const [];
  List<WorkPackage> _recentlyOpened = const [];
  List<SavedQuery> _views = const [];
  Version? _activeVersion;
  int _totalOpenCount = 0;

  bool _showStatusChart = true;
  bool _showTypeChart = true;
  bool _showTimeSeriesChart = true;
  bool _showUpcoming = true;
  DashboardChartType _statusChartType = DashboardChartType.bar;
  DashboardChartType _typeChartType = DashboardChartType.pie;

  @override
  void initState() {
    super.initState();
    _load();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final showStatus = await DashboardPrefs.getShowStatusChart();
    final showType = await DashboardPrefs.getShowTypeChart();
    final showTimeSeries = await DashboardPrefs.getShowTimeSeriesChart();
    final showUpcoming = await DashboardPrefs.getShowUpcoming();
    final statusTypeStr = await DashboardPrefs.getStatusChartType();
    final typeTypeStr = await DashboardPrefs.getTypeChartType();
    if (!mounted) return;
    setState(() {
      _showStatusChart = showStatus;
      _showTypeChart = showType;
      _showTimeSeriesChart = showTimeSeries;
      _showUpcoming = showUpcoming;
      final statusMatch = DashboardChartType.values.where((e) => e.name == statusTypeStr);
      _statusChartType = statusMatch.isEmpty ? DashboardChartType.bar : statusMatch.first;
      final typeMatch = DashboardChartType.values.where((e) => e.name == typeTypeStr);
      _typeChartType = typeMatch.isEmpty ? DashboardChartType.pie : typeMatch.first;
    });
  }

  OpenProjectClient? _client(BuildContext context) => context.read<AuthState>().client;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthState>();
      final client = _client(context);
      if (client == null) throw Exception('Oturum bulunamadı.');
      final projectId = auth.activeProject?.id;
      if (projectId == null || projectId.isEmpty) {
        throw Exception('Aktif proje bulunamadı.');
      }

      final versions = await client.getProjectVersions(projectId);
      Version? active;
      for (final v in versions) {
        if (v.isOpen) {
          active = v;
          break;
        }
      }
      _activeVersion = active;

      final extraFilters = _activeVersion != null
          ? <Map<String, dynamic>>[
              {'version': {'operator': '=', 'values': ['${_activeVersion!.id}']}},
            ]
          : null;
      final result = await client.getMyOpenWorkPackages(
        projectId: projectId,
        pageSize: 200,
        offset: 1,
        extraFilters: extraFilters,
      );
      _items = result.workPackages;

      if (_activeVersion != null) {
        final totalResult = await client.getMyOpenWorkPackages(
          projectId: projectId,
          pageSize: 1,
          offset: 1,
        );
        _totalOpenCount = totalResult.total;
      } else {
        _totalOpenCount = _items.length;
      }

      final recentIds = await DashboardPrefs.getRecentlyOpenedIds();
      if (recentIds.isNotEmpty) {
        final recent = await client.getWorkPackagesByIds(recentIds);
        final byId = {for (final wp in recent) wp.id: wp};
        _recentlyOpened = recentIds.map((id) => byId[id]).whereType<WorkPackage>().toList();
      } else {
        _recentlyOpened = const [];
      }

      final views = await client.getQueries(projectId: projectId);
      final list = views.where((q) => !q.hidden).toList();
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _views = list;
    } catch (e) {
      _error = ErrorMessages.userFriendly(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _openCount => _items.length;

  int get _overdueCount {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _items.where((wp) {
      final d = wp.dueDate;
      if (d == null) return false;
      final dd = DateTime(d.year, d.month, d.day);
      return dd.isBefore(today);
    }).length;
  }

  int get _todayCount {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _items.where((wp) {
      final d = wp.dueDate;
      if (d == null) return false;
      final dd = DateTime(d.year, d.month, d.day);
      return dd == today;
    }).length;
  }

  Map<String, int> get _statusCounts {
    final map = <String, int>{};
    for (final wp in _items) {
      final key = wp.statusName;
      map[key] = (map[key] ?? 0) + 1;
    }
    return map;
  }

  Map<String, int> get _typeCounts {
    final map = <String, int>{};
    for (final wp in _items) {
      final key = wp.typeName ?? 'Belirtilmemiş';
      map[key] = (map[key] ?? 0) + 1;
    }
    return map;
  }

  /// Önümüzdeki 14 gün + bugün için günlük bitiş tarihi sayıları (yyyy-MM-dd -> count).
  Map<String, int> get _dueCountByDay {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final map = <String, int>{};
    for (var i = 0; i < 15; i++) {
      final d = today.add(Duration(days: i));
      map['${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}'] = 0;
    }
    for (final wp in _items) {
      final d = wp.dueDate;
      if (d == null) continue;
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      if (map.containsKey(key)) map[key] = (map[key] ?? 0) + 1;
    }
    return map;
  }

  List<WorkPackage> get _upcoming {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final list = _items.where((wp) {
      final d = wp.dueDate;
      if (d == null) return false;
      final dd = DateTime(d.year, d.month, d.day);
      return !dd.isBefore(today);
    }).toList();
    list.sort((a, b) {
      final ad = a.dueDate!;
      final bd = b.dueDate!;
      return ad.compareTo(bd);
    });
    return list.take(5).toList();
  }

  /// Son güncellenen işler (updatedAt'e göre azalan, en fazla 8).
  List<WorkPackage> get _recentlyUpdated {
    final list = List<WorkPackage>.from(_items);
    list.sort((a, b) {
      final ad = a.updatedAt ?? DateTime(0);
      final bd = b.updatedAt ?? DateTime(0);
      return bd.compareTo(ad);
    });
    return list.take(8).toList();
  }

  /// Sprint'teki işler önceliğe göre (priorityName, sonra subject).
  List<WorkPackage> get _sprintWorkByPriority {
    final list = List<WorkPackage>.from(_items);
    list.sort((a, b) {
      final pa = a.priorityName ?? '';
      final pb = b.priorityName ?? '';
      final cmp = pa.compareTo(pb);
      if (cmp != 0) return cmp;
      final sa = a.statusName;
      final sb = b.statusName;
      final cmp2 = sa.compareTo(sb);
      if (cmp2 != 0) return cmp2;
      final ta = a.typeName ?? '';
      final tb = b.typeName ?? '';
      final cmp3 = ta.compareTo(tb);
      if (cmp3 != 0) return cmp3;
      return a.subject.compareTo(b.subject);
    });
    return list;
  }

  /// Sprint işlerini yalnızca önceliğe göre gruplar (başlık + liste); satırda durum ve tip gösterilir.
  List<({String label, List<WorkPackage> items})> get _sprintWorkGrouped {
    final list = _sprintWorkByPriority;
    if (list.isEmpty) return [];
    final result = <({String label, List<WorkPackage> items})>[];
    String? curPriority;
    List<WorkPackage> cur = [];
    void flush() {
      if (cur.isEmpty) return;
      result.add((label: curPriority != null && curPriority!.isNotEmpty ? 'Öncelik: $curPriority' : 'Öncelik belirtilmemiş', items: List.from(cur)));
      cur = [];
    }
    for (final wp in list) {
      final p = wp.priorityName ?? '';
      if (p != curPriority) {
        flush();
        curPriority = p.isEmpty ? null : p;
      }
      cur.add(wp);
    }
    flush();
    return result;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    final d = date.toLocal();
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  /// Diğer listelerle aynı: durum için renk ve ikon.
  (Color bg, Color fg, IconData icon) _statusVisuals(BuildContext context, String status) {
    final theme = Theme.of(context);
    final s = status.toLowerCase();
    if (s.contains('yeni') || s.contains('new')) {
      return (theme.colorScheme.primaryContainer, theme.colorScheme.onPrimaryContainer, Icons.fiber_new_rounded);
    }
    if (s.contains('devam') || s.contains('progress') || s.contains('in progress')) {
      return (theme.colorScheme.tertiaryContainer, theme.colorScheme.onTertiaryContainer, Icons.play_circle_rounded);
    }
    if (s.contains('bekle') || s.contains('on hold') || s.contains('pending')) {
      return (theme.colorScheme.surfaceVariant, theme.colorScheme.onSurfaceVariant, Icons.pause_circle_rounded);
    }
    if (s.contains('tamam') || s.contains('closed') || s.contains('done') || s.contains('çözüldü')) {
      return (theme.colorScheme.secondaryContainer, theme.colorScheme.onSecondaryContainer, Icons.check_circle_rounded);
    }
    if (s.contains('iptal') || s.contains('cancel')) {
      return (theme.colorScheme.errorContainer, theme.colorScheme.onErrorContainer, Icons.cancel_rounded);
    }
    return (theme.colorScheme.primaryContainer, theme.colorScheme.onPrimaryContainer, Icons.radio_button_unchecked_rounded);
  }

  /// Diğer listelerle aynı: iş tipi için renk ve ikon.
  (Color bg, Color fg, IconData icon) _typeVisuals(BuildContext context, String type) {
    final theme = Theme.of(context);
    final t = (type.isEmpty ? '—' : type).toLowerCase();
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
    return (theme.colorScheme.surfaceVariant, theme.colorScheme.onSurfaceVariant, Icons.label_rounded);
  }

  /// Öncelik için renk ve ikon (diğer listelerdeki chip stiliyle uyumlu).
  (Color bg, Color fg, IconData icon) _priorityVisuals(BuildContext context, String priority) {
    final theme = Theme.of(context);
    final p = (priority.isEmpty ? '' : priority).toLowerCase();
    if (p.contains('acil') || p.contains('urgent') || p.contains('yüksek') || p.contains('high') || p.contains('critical')) {
      return (theme.colorScheme.errorContainer, theme.colorScheme.onErrorContainer, Icons.priority_high_rounded);
    }
    if (p.contains('orta') || p.contains('medium') || p.contains('normal')) {
      return (theme.colorScheme.tertiaryContainer, theme.colorScheme.onTertiaryContainer, Icons.remove_circle_outline_rounded);
    }
    if (p.contains('düşük') || p.contains('low')) {
      return (theme.colorScheme.surfaceVariant, theme.colorScheme.onSurfaceVariant, Icons.low_priority_rounded);
    }
    return (theme.colorScheme.surfaceVariant, theme.colorScheme.onSurfaceVariant, Icons.flag_rounded);
  }

  Widget _buildMetaChip(BuildContext context, {required Color bg, required Color fg, required IconData icon, required String text}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 3),
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(color: fg, fontSize: 10),
          ),
        ],
      ),
    );
  }

  void _openSettingsSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        bool showStatus = _showStatusChart;
        bool showType = _showTypeChart;
        bool showTimeSeries = _showTimeSeriesChart;
        bool showUpcoming = _showUpcoming;
        var statusType = _statusChartType;
        var typeType = _typeChartType;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ListTile(
                      title: Text('Dashboard ayarları'),
                      subtitle: Text('Gösterilecek bileşenler ve grafik türleri'),
                    ),
                    SwitchListTile(
                      value: showStatus,
                      title: const Text('Duruma göre dağılım'),
                      onChanged: (v) {
                        setModalState(() => showStatus = v);
                        setState(() => _showStatusChart = v);
                        DashboardPrefs.setShowStatusChart(v);
                      },
                    ),
                    ListTile(
                      title: const Text('Durum grafik türü'),
                      subtitle: Text(statusType.label),
                      trailing: DropdownButton<DashboardChartType>(
                        value: statusType,
                        items: DashboardChartType.values
                            .where((e) => e != DashboardChartType.timeSeries)
                            .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setModalState(() => statusType = v);
                          setState(() => _statusChartType = v);
                          DashboardPrefs.setStatusChartType(v.name);
                        },
                      ),
                    ),
                    SwitchListTile(
                      value: showType,
                      title: const Text('İş tipine göre dağılım'),
                      onChanged: (v) {
                        setModalState(() => showType = v);
                        setState(() => _showTypeChart = v);
                        DashboardPrefs.setShowTypeChart(v);
                      },
                    ),
                    ListTile(
                      title: const Text('İş tipi grafik türü'),
                      subtitle: Text(typeType.label),
                      trailing: DropdownButton<DashboardChartType>(
                        value: typeType,
                        items: DashboardChartType.values
                            .where((e) => e != DashboardChartType.timeSeries)
                            .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setModalState(() => typeType = v);
                          setState(() => _typeChartType = v);
                          DashboardPrefs.setTypeChartType(v.name);
                        },
                      ),
                    ),
                    SwitchListTile(
                      value: showTimeSeries,
                      title: const Text('Bitiş tarihine göre (zaman grafiği)'),
                      subtitle: const Text('Önümüzdeki 15 gün, günlük iş sayısı'),
                      onChanged: (v) {
                        setModalState(() => showTimeSeries = v);
                        setState(() => _showTimeSeriesChart = v);
                        DashboardPrefs.setShowTimeSeriesChart(v);
                      },
                    ),
                    SwitchListTile(
                      value: showUpcoming,
                      title: const Text('Yaklaşan bitiş tarihleri listesi'),
                      onChanged: (v) {
                        setModalState(() => showUpcoming = v);
                        setState(() => _showUpcoming = v);
                        DashboardPrefs.setShowUpcoming(v);
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChart(
    BuildContext context,
    Map<String, int> data,
    Color baseColor,
    DashboardChartType type,
  ) {
    switch (type) {
      case DashboardChartType.bar:
        return _BarChart(data: data, color: baseColor);
      case DashboardChartType.horizontalBar:
        return _HorizontalBarChart(data: data, color: baseColor);
      case DashboardChartType.pie:
        return _PieChart(data: data, theme: Theme.of(context));
      case DashboardChartType.donut:
        return _DonutChart(data: data, theme: Theme.of(context));
      case DashboardChartType.timeSeries:
        return _BarChart(data: data, color: baseColor);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final theme = Theme.of(context);
    final projectName = auth.activeProject?.name ?? 'Dashboard';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          projectName,
          style: theme.textTheme.titleMedium,
        ),
        actions: [
          const ProjectFlowLogoButton(),
          IconButton(
            onPressed: () {
              lightImpact();
              Navigator.of(context).pushNamed('/time-tracking');
            },
            icon: const Icon(Icons.schedule, size: 20),
            tooltip: 'Zaman takibi',
          ),
          IconButton(
            onPressed: () {
              lightImpact();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyWorkPackagesScreen()),
              );
            },
            icon: const Icon(Icons.list_alt, size: 20),
            tooltip: 'Benim işlerim',
          ),
          IconButton(
            onPressed: () {
              lightImpact();
              _openSettingsSheet();
            },
            icon: const Icon(Icons.tune, size: 20),
            tooltip: 'Dashboard ayarları',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          mediumImpact();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MyWorkPackagesScreen()),
          );
        },
        tooltip: 'Benim işlerim',
        child: const Icon(Icons.list_alt),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _load,
                          child: const Text('Tekrar dene'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_activeVersion != null) ...[
                                Expanded(
                                  child: _DashboardStatCard(
                                    title: 'Aktif sprint',
                                    value: _activeVersion!.name,
                                    color: theme.colorScheme.primary,
                                    valueIsLabel: true,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _DashboardStatCard(
                                    title: 'Sprint\'teki işlerim',
                                    value: _openCount.toString(),
                                    color: theme.colorScheme.tertiary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _DashboardStatCard(
                                    title: 'Bekleyen toplam',
                                    value: _totalOpenCount.toString(),
                                    color: theme.colorScheme.secondary,
                                  ),
                                ),
                              ] else ...[
                                Expanded(
                                  child: _DashboardStatCard(
                                    title: 'Açık işler',
                                    value: _openCount.toString(),
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_activeVersion != null && _sprintWorkGrouped.isNotEmpty) ...[
                          Text(
                            'Sprint\'teki işlerim (öncelik · durum · tip)',
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (var g = 0; g < _sprintWorkGrouped.length; g++) ...[
                                  if (g > 0) const Divider(height: 1),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                                    child: Text(
                                      _sprintWorkGrouped[g].label,
                                      style: theme.textTheme.labelLarge?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  ..._sprintWorkGrouped[g].items.map((wp) {
                                    final auth = context.read<AuthState>();
                                    final displayName = (wp.assigneeName ?? '').trim();
                                    final apiBaseUrl = (auth.instanceApiBaseUrl ?? '').trim();
                                    final assigneeId = (wp.assigneeId ?? '').trim();
                                    final avatarUrl = (apiBaseUrl.isNotEmpty && assigneeId.isNotEmpty)
                                        ? '$apiBaseUrl/users/$assigneeId/avatar'
                                        : null;
                                    final priorityText = wp.priorityName ?? 'Öncelik yok';
                                    final statusVs = _statusVisuals(context, wp.statusName);
                                    final typeVs = _typeVisuals(context, wp.typeName ?? '—');
                                    final priorityVs = _priorityVisuals(context, priorityText);
                                    final meta = <Widget>[
                                      _buildMetaChip(context, bg: priorityVs.$1, fg: priorityVs.$2, icon: priorityVs.$3, text: priorityText),
                                      _buildMetaChip(context, bg: statusVs.$1, fg: statusVs.$2, icon: statusVs.$3, text: wp.statusName),
                                      _buildMetaChip(context, bg: typeVs.$1, fg: typeVs.$2, icon: typeVs.$3, text: wp.typeName ?? '—'),
                                    ];
                                    return ListTile(
                                      dense: true,
                                      leading: displayName.isNotEmpty
                                          ? LetterAvatar(
                                              displayName: displayName,
                                              imageUrl: avatarUrl,
                                              imageHeaders: avatarUrl != null ? auth.authHeadersForInstanceImages : null,
                                              size: 36,
                                            )
                                          : null,
                                      title: Text(
                                        '#${wp.id} · ${wp.subject}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: meta,
                                        ),
                                      ),
                                      trailing: const Icon(Icons.chevron_right, size: 20),
                                      onTap: () {
                                        lightImpact();
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                WorkPackageDetailScreen(workPackage: wp),
                                          ),
                                        );
                                      },
                                    );
                                  }),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_views.isNotEmpty) ...[
                          Text(
                            'Kolay erişim – Görünümler',
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Card(
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _views.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final view = _views[index];
                                return ListTile(
                                  leading: Icon(
                                    view.starred ? Icons.star : Icons.view_list,
                                    size: 24,
                                    color: view.starred
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                  title: Text(
                                    view.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: view.projectId == null
                                      ? const Text('Tüm projeler')
                                      : null,
                                  trailing: const Icon(Icons.chevron_right, size: 20),
                                  onTap: () {
                                    lightImpact();
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => MyWorkPackagesScreen(initialQuery: view),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_recentlyOpened.isNotEmpty) ...[
                          Text(
                            'Son açılan işler',
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Card(
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _recentlyOpened.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final wp = _recentlyOpened[index];
                                final auth = context.read<AuthState>();
                                final displayName = (wp.assigneeName ?? '').trim();
                                final apiBaseUrl = (auth.instanceApiBaseUrl ?? '').trim();
                                final assigneeId = (wp.assigneeId ?? '').trim();
                                final avatarUrl = (apiBaseUrl.isNotEmpty && assigneeId.isNotEmpty)
                                    ? '$apiBaseUrl/users/$assigneeId/avatar'
                                    : null;
                                return ListTile(
                                  leading: displayName.isNotEmpty
                                      ? LetterAvatar(
                                          displayName: displayName,
                                          imageUrl: avatarUrl,
                                          imageHeaders: avatarUrl != null ? auth.authHeadersForInstanceImages : null,
                                          size: 40,
                                        )
                                      : null,
                                  title: Text(
                                    '#${wp.id} · ${wp.subject}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    '${wp.statusName} · Güncelleme: ${_formatDate(wp.updatedAt)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: const Icon(Icons.chevron_right, size: 20),
                                  onTap: () {
                                    lightImpact();
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            WorkPackageDetailScreen(workPackage: wp),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_recentlyUpdated.isNotEmpty) ...[
                          Text(
                            'Son yapılan değişiklikler',
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Card(
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _recentlyUpdated.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final wp = _recentlyUpdated[index];
                                final auth = context.read<AuthState>();
                                final displayName = (wp.assigneeName ?? '').trim();
                                final apiBaseUrl = (auth.instanceApiBaseUrl ?? '').trim();
                                final assigneeId = (wp.assigneeId ?? '').trim();
                                final avatarUrl = (apiBaseUrl.isNotEmpty && assigneeId.isNotEmpty)
                                    ? '$apiBaseUrl/users/$assigneeId/avatar'
                                    : null;
                                return ListTile(
                                  leading: displayName.isNotEmpty
                                      ? LetterAvatar(
                                          displayName: displayName,
                                          imageUrl: avatarUrl,
                                          imageHeaders: avatarUrl != null ? auth.authHeadersForInstanceImages : null,
                                          size: 40,
                                        )
                                      : null,
                                  title: Text(
                                    '#${wp.id} · ${wp.subject}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    '${wp.statusName} · Son güncelleme: ${_formatDate(wp.updatedAt)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: const Icon(Icons.chevron_right, size: 20),
                                  onTap: () {
                                    lightImpact();
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            WorkPackageDetailScreen(workPackage: wp),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_showStatusChart && _statusCounts.isNotEmpty) ...[
                          Text(
                            'Duruma göre dağılım',
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          _buildChart(
                            context,
                            _statusCounts,
                            theme.colorScheme.primary,
                            _statusChartType,
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_showTypeChart && _typeCounts.isNotEmpty) ...[
                          Text(
                            'İş tipine göre dağılım',
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          _buildChart(
                            context,
                            _typeCounts,
                            theme.colorScheme.secondary,
                            _typeChartType,
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_showTimeSeriesChart && _dueCountByDay.isNotEmpty) ...[
                          Text(
                            'Bitiş tarihine göre (önümüzdeki 15 gün)',
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          _TimeSeriesChart(
                            data: _dueCountByDay,
                            color: theme.colorScheme.tertiary,
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_showUpcoming) ...[
                          Text(
                            'Yaklaşan bitiş tarihleri',
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          if (_upcoming.isEmpty)
                            Text(
                              'Yaklaşan bitiş tarihi olan iş bulunmuyor.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            )
                          else
                            Card(
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _upcoming.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final wp = _upcoming[index];
                                  final auth = context.read<AuthState>();
                                  final displayName = (wp.assigneeName ?? '').trim();
                                  final apiBaseUrl = (auth.instanceApiBaseUrl ?? '').trim();
                                  final assigneeId = (wp.assigneeId ?? '').trim();
                                  final avatarUrl = (apiBaseUrl.isNotEmpty && assigneeId.isNotEmpty)
                                      ? '$apiBaseUrl/users/$assigneeId/avatar'
                                      : null;
                                  return ListTile(
                                    leading: displayName.isNotEmpty
                                        ? LetterAvatar(
                                            displayName: displayName,
                                            imageUrl: avatarUrl,
                                            imageHeaders: avatarUrl != null ? auth.authHeadersForInstanceImages : null,
                                            size: 40,
                                          )
                                        : null,
                                    title: Text(
                                      wp.subject,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      'Bitiş: ${_formatDate(wp.dueDate)} · Durum: ${wp.statusName}'
                                          '${(wp.assigneeName ?? '').isNotEmpty ? ' · ${wp.assigneeName}' : ''}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    onTap: () {
                                      lightImpact();
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              WorkPackageDetailScreen(workPackage: wp),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _DashboardStatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final bool valueIsLabel;

  const _DashboardStatCard({
    required this.title,
    required this.value,
    required this.color,
    this.valueIsLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: valueIsLabel ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: (valueIsLabel ? theme.textTheme.titleSmall : theme.textTheme.titleMedium)?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  final Map<String, int> data;
  final Color color;

  const _BarChart({required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (data.isEmpty) {
      return const SizedBox.shrink();
    }
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = entries.map((e) => e.value).fold(0, (a, b) => a > b ? a : b);

    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: entries.map((e) {
          final ratio = maxVal > 0 ? (e.value / maxVal) : 0.0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: 120 * ratio,
                        width: 16,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    e.key,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${e.value}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Yatay çubuk grafik: etiket solda, çubuk sağa doğru.
class _HorizontalBarChart extends StatelessWidget {
  final Map<String, int> data;
  final Color color;

  const _HorizontalBarChart({required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (data.isEmpty) return const SizedBox.shrink();
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = entries.map((e) => e.value).fold(0, (a, b) => a > b ? a : b);

    return SizedBox(
      height: 56.0 * entries.length.clamp(1, 8),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: entries.length,
        itemBuilder: (context, i) {
          final e = entries[i];
          final ratio = maxVal > 0 ? (e.value / maxVal) : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    e.key,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall,
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Container(
                            height: 24,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: ratio,
                            child: Container(
                              height: 24,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 28,
                  child: Text(
                    '${e.value}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// FractionallySizedBox: widthFactor ile genişlik veren wrapper.
class FractionallySizedBox extends StatelessWidget {
  final double widthFactor;
  final Widget child;

  const FractionallySizedBox({
    super.key,
    required this.widthFactor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = (constraints.maxWidth * widthFactor.clamp(0.0, 1.0)).clamp(0.0, double.infinity);
        return SizedBox(width: w, child: child);
      },
    );
  }
}

/// Pasta grafik (CustomPainter).
class _PieChart extends StatelessWidget {
  final Map<String, int> data;
  final ThemeData theme;

  const _PieChart({required this.data, required this.theme});

  static List<Color> _palette(ThemeData t) => [
        t.colorScheme.primary,
        t.colorScheme.secondary,
        t.colorScheme.tertiary,
        t.colorScheme.error,
        t.colorScheme.primaryContainer,
        t.colorScheme.secondaryContainer,
        t.colorScheme.tertiaryContainer,
      ];

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final total = data.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();
    final entries = data.entries.toList();
    final colors = _palette(theme);
    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: CustomPaint(
              size: const Size(double.infinity, 200),
              painter: _PiePainter(
                data: entries.map((e) => e.value / total).toList(),
                colors: List.generate(entries.length, (i) => colors[i % colors.length]),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: entries.asMap().entries.map((entry) {
                final i = entry.key;
                final e = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: colors[i % colors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${e.key} (${e.value})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PiePainter extends CustomPainter {
  final List<double> data;
  final List<Color> colors;

  _PiePainter({required this.data, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 * 0.85;
    var start = -math.pi / 2;
    for (var i = 0; i < data.length; i++) {
      final sweep = 2 * math.pi * data[i];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        true,
        Paint()..color = colors[i],
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Halka (donut) grafik.
class _DonutChart extends StatelessWidget {
  final Map<String, int> data;
  final ThemeData theme;

  const _DonutChart({required this.data, required this.theme});

  static List<Color> _palette(ThemeData t) => _PieChart._palette(t);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final total = data.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();
    final entries = data.entries.toList();
    final colors = _palette(theme);
    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: CustomPaint(
              size: const Size(double.infinity, 200),
              painter: _DonutPainter(
                data: entries.map((e) => e.value / total).toList(),
                colors: List.generate(entries.length, (i) => colors[i % colors.length]),
                holeColor: theme.colorScheme.surface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: entries.asMap().entries.map((entry) {
                final i = entry.key;
                final e = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: colors[i % colors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${e.key} (${e.value})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<double> data;
  final List<Color> colors;
  final Color holeColor;

  _DonutPainter({required this.data, required this.colors, required this.holeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 * 0.85;
    const holeRatio = 0.5;
    var start = -math.pi / 2;
    for (var i = 0; i < data.length; i++) {
      final sweep = 2 * math.pi * data[i];
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(rect, start, sweep, true, Paint()..color = colors[i]);
      start += sweep;
    }
    canvas.drawCircle(
      center,
      radius * holeRatio,
      Paint()..color = holeColor,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Zaman serisi: tarih (gün) -> sayı. X: günler, Y: iş sayısı.
class _TimeSeriesChart extends StatelessWidget {
  final Map<String, int> data;
  final Color color;

  const _TimeSeriesChart({required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (data.isEmpty) return const SizedBox.shrink();
    final entries = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final maxVal = entries.map((e) => e.value).fold(0, (a, b) => a > b ? a : b);

    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: entries.map((e) {
          final ratio = maxVal > 0 ? (e.value / maxVal) : 0.0;
          final label = e.key.length >= 10 ? e.key.substring(8, 10) : e.key;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: 100 * ratio,
                        width: 12,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: theme.textTheme.labelSmall,
                  ),
                  Text(
                    '${e.value}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

