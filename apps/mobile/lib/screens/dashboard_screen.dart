import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_navigation.dart';
import '../mixins/client_context_mixin.dart';
import '../mixins/loading_error_mixin.dart';
import '../models/saved_query.dart';
import '../models/version.dart';
import '../models/work_package.dart';
import '../state/auth_state.dart';
import '../state/dashboard_prefs.dart';
import '../state/pro_state.dart';
import '../utils/app_logger.dart';
import '../utils/date_formatters.dart';
import '../utils/haptic.dart';
import '../widgets/async_content.dart';
import '../widgets/dashboard_chart_section.dart';
import '../widgets/letter_avatar.dart';
import '../widgets/work_package_visuals.dart';
import '../widgets/projectflow_logo_button.dart';
import 'my_work_packages_screen.dart';
import 'work_package_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.isInsideShell = false});

  /// Alt navigasyon kabuğu içinde gösteriliyorsa true; AppBar’da tekrarlanan nav aksiyonları gizlenir.
  final bool isInsideShell;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with ClientContextMixin<DashboardScreen>, LoadingErrorMixin<DashboardScreen> {
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

  /// Bölüm anahtarı -> açık mı (true = açık).
  final Map<String, bool> _sectionExpanded = <String, bool>{
    'sprint': true,
    'views': true,
    'recentlyOpened': true,
    'recentlyUpdated': true,
    'statusChart': true,
    'typeChart': true,
    'timeSeries': true,
    'upcoming': true,
  };

  void _toggleSection(String key) {
    setState(() {
      _sectionExpanded[key] = !(_sectionExpanded[key] ?? true);
    });
  }

  @override
  void initState() {
    super.initState();
    loading = true;
    _load();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    try {
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
    } catch (e, st) {
      AppLogger.logError('Dashboard ayarları yüklenirken hata', error: e, stackTrace: st);
      if (mounted) setState(() {});
    }
  }

  Future<void> _load() async {
    await runLoad(() async {
      final auth = context.read<AuthState>();
      final c = client;
      if (c == null) throw Exception('Oturum bulunamadı.');
      final projectId = auth.activeProject?.id;
      if (projectId == null || projectId.isEmpty) {
        throw Exception('Aktif proje bulunamadı.');
      }

      final versions = await c.getProjectVersions(projectId);
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
      final result = await c.getMyOpenWorkPackages(
        projectId: projectId,
        pageSize: 200,
        offset: 1,
        extraFilters: extraFilters,
      );
      _items = result.workPackages;

      if (_activeVersion != null) {
        final totalResult = await c.getMyOpenWorkPackages(
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
        try {
          final recent = await c.getWorkPackagesByIds(recentIds);
          final byId = {for (final wp in recent) wp.id: wp};
          _recentlyOpened = recentIds.map((id) => byId[id]).whereType<WorkPackage>().toList();
        } catch (e) {
          AppLogger.logError('Dashboard son açılanlar yüklenemedi', error: e);
          _recentlyOpened = const [];
        }
      } else {
        _recentlyOpened = const [];
      }

      final views = await c.getQueries(projectId: projectId);
      final list = views.where((q) => !q.hidden).toList();
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _views = list;
    }, onError: (e) => AppLogger.logError('Dashboard yüklenirken hata', error: e));
  }

  int get _openCount => _items.length;

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
      map[DateFormatters.formatDateKey(d)] = 0;
    }
    for (final wp in _items) {
      final d = wp.dueDate;
      if (d == null) continue;
      final key = DateFormatters.formatDateKey(d);
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
      final ad = a.dueDate ?? DateTime(0);
      final bd = b.dueDate ?? DateTime(0);
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
      result.add((label: (curPriority != null && curPriority.isNotEmpty) ? 'Öncelik: $curPriority' : 'Öncelik belirtilmemiş', items: List.from(cur)));
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

  Widget _buildCollapsibleSection({
    required String sectionKey,
    required String title,
    required Widget child,
    IconData titleIcon = Icons.folder_rounded,
    Widget? titleTrailing,
  }) {
    final expanded = _sectionExpanded[sectionKey] ?? true;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () {
              lightImpact();
              _toggleSection(sectionKey);
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(titleIcon, size: 22, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (titleTrailing != null) ...[
                    titleTrailing,
                    const SizedBox(width: 8),
                  ],
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 28,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (expanded) ...[
          const SizedBox(height: 8),
          child,
        ],
        const SizedBox(height: 16),
      ],
    );
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
            style: theme.textTheme.labelSmall?.copyWith(color: fg),
          ),
        ],
      ),
    );
  }

  void _openSettingsSheet() {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
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
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final chosen = await showModalBottomSheet<DashboardChartType>(
                          context: context,
                          useSafeArea: true,
                          builder: (ctx) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                                  child: Text(
                                    'Durum grafik türü',
                                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                ...DashboardChartType.values
                                    .where((e) => e != DashboardChartType.timeSeries)
                                    .map((e) => ListTile(
                                          title: Text(e.label),
                                          selected: statusType == e,
                                          leading: statusType == e ? Icon(Icons.check_rounded, color: Theme.of(ctx).colorScheme.primary) : null,
                                          onTap: () => Navigator.of(ctx).pop(e),
                                        )),
                              ],
                            ),
                          ),
                        );
                        if (chosen != null) {
                          setModalState(() => statusType = chosen);
                          setState(() => _statusChartType = chosen);
                          DashboardPrefs.setStatusChartType(chosen.name);
                        }
                      },
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
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final chosen = await showModalBottomSheet<DashboardChartType>(
                          context: context,
                          useSafeArea: true,
                          builder: (ctx) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                                  child: Text(
                                    'İş tipi grafik türü',
                                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                ...DashboardChartType.values
                                    .where((e) => e != DashboardChartType.timeSeries)
                                    .map((e) => ListTile(
                                          title: Text(e.label),
                                          selected: typeType == e,
                                          leading: typeType == e ? Icon(Icons.check_rounded, color: Theme.of(ctx).colorScheme.primary) : null,
                                          onTap: () => Navigator.of(ctx).pop(e),
                                        )),
                              ],
                            ),
                          ),
                        );
                        if (chosen != null) {
                          setModalState(() => typeType = chosen);
                          setState(() => _typeChartType = chosen);
                          DashboardPrefs.setTypeChartType(chosen.name);
                        }
                      },
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
    final theme = Theme.of(context);
    switch (type) {
      case DashboardChartType.bar:
        return BarChart(data: data, color: baseColor);
      case DashboardChartType.horizontalBar:
        return HorizontalBarChart(data: data, color: baseColor);
      case DashboardChartType.pie:
        return PieChart(data: data, theme: theme);
      case DashboardChartType.donut:
        return DonutChart(data: data, theme: theme);
      case DashboardChartType.timeSeries:
        return BarChart(data: data, color: baseColor);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final isPro = context.watch<ProState>().isPro;
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
          Semantics(
            label: 'Menü',
            button: true,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              tooltip: 'Menü',
              onSelected: (value) {
                lightImpact();
                switch (value) {
                  case 'profile':
                    Navigator.of(context).pushNamed(AppRoutes.profile);
                    break;
                  case 'my_work':
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MyWorkPackagesScreen()),
                    ).then((_) => _load());
                    break;
                  case 'time_tracking':
                    Navigator.of(context).pushNamed(AppRoutes.timeTracking);
                    break;
                  case 'notifications':
                    if (!widget.isInsideShell) Navigator.of(context).pushNamed(AppRoutes.notifications);
                    break;
                  case 'settings':
                    _openSettingsSheet();
                    break;
                }
              },
              itemBuilder: (context) {
                final theme = Theme.of(context);
                final colorScheme = theme.colorScheme;
                return [
                  if (!widget.isInsideShell)
                    PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_outline, size: 22, color: colorScheme.onSurface),
                          const SizedBox(width: 12),
                          Text('Profil', style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'my_work',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.list_alt_outlined, size: 22, color: colorScheme.onSurface),
                        const SizedBox(width: 12),
                        Text('Benim işlerim', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'time_tracking',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.schedule_outlined, size: 22, color: colorScheme.onSurface),
                        const SizedBox(width: 12),
                        Text('Zaman takibi', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  if (!widget.isInsideShell)
                    PopupMenuItem(
                      value: 'notifications',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_outlined, size: 22, color: colorScheme.onSurface),
                          const SizedBox(width: 12),
                          Text('Bildirimler', style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.tune, size: 22, color: colorScheme.onSurface),
                        const SizedBox(width: 12),
                        Text('Dashboard ayarları', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ];
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Semantics(
        label: 'Yeni iş paketi oluştur',
        button: true,
        child: FloatingActionButton(
          heroTag: 'dashboard_add_work',
          onPressed: () {
            mediumImpact();
            NavHelpers.toCreateWorkPackage(context, onPopped: _load);
          },
          tooltip: 'Yeni iş paketi',
          child: const Icon(Icons.add_rounded),
        ),
      ),
      body: AsyncContent(
        loading: loading,
        error: error,
        onRetry: _load,
        child: RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _DashboardStatsRow(
                          activeVersion: _activeVersion,
                          openCount: _openCount,
                          totalOpenCount: _totalOpenCount,
                        ),
                        const SizedBox(height: 16),
                        if (_activeVersion != null && _sprintWorkGrouped.isNotEmpty)
                          _buildCollapsibleSection(
                            sectionKey: 'sprint',
                            title: 'Sprint\'teki işlerim (öncelik · durum · tip)',
                            titleIcon: Icons.assignment_rounded,
                            child: Card(
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
                                    final statusVs = WorkPackageVisuals.statusVisuals(context, wp.statusName);
                                    final typeVs = WorkPackageVisuals.typeVisuals(context, wp.typeName ?? '—');
                                    final priorityVs = WorkPackageVisuals.priorityVisuals(context, priorityText);
                                    final meta = <Widget>[
                                      _buildMetaChip(context, bg: priorityVs.$1, fg: priorityVs.$2, icon: priorityVs.$3, text: priorityText),
                                      _buildMetaChip(context, bg: statusVs.$1, fg: statusVs.$2, icon: statusVs.$3, text: wp.statusName),
                                      _buildMetaChip(context, bg: typeVs.$1, fg: typeVs.$2, icon: typeVs.$3, text: wp.typeName ?? '—'),
                                    ];
                                    return ListTile(
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
                                        ).then((_) {
                                          if (mounted) _load();
                                        });
                                      },
                                    );
                                  }),
                                ],
                              ],
                            ),
                          ),
                        ),
                        if (_views.isNotEmpty)
                          _buildCollapsibleSection(
                            sectionKey: 'views',
                            title: 'Kolay erişim – Görünümler',
                            titleIcon: Icons.view_list_rounded,
                            titleTrailing: isPro
                                ? null
                                : Icon(
                                    Icons.star_rounded,
                                    size: 18,
                                    color: theme.colorScheme.primary,
                                  ),
                            child: Card(
                              child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _views.length,
                              separatorBuilder: (_, _) => const Divider(height: 1),
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
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!isPro) ...[
                                        Icon(
                                          Icons.star_rounded,
                                          size: 16,
                                          color: theme.colorScheme.primary,
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                      const Icon(Icons.chevron_right, size: 20),
                                    ],
                                  ),
                                  onTap: () {
                                    lightImpact();
                                    if (!isPro) {
                                      Navigator.of(context).pushNamed(AppRoutes.proUpgrade);
                                      return;
                                    }
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
                        ),
                        if (_recentlyOpened.isNotEmpty)
                          _buildCollapsibleSection(
                            sectionKey: 'recentlyOpened',
                            title: 'Son açılan işler',
                            titleIcon: Icons.history_rounded,
                            child: Card(
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _recentlyOpened.length,
                                separatorBuilder: (_, _) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final wp = _recentlyOpened[index];
                                  final auth = context.read<AuthState>();
                                  final displayName = (wp.assigneeName ?? '').trim();
                                  final apiBaseUrl = (auth.instanceApiBaseUrl ?? '').trim();
                                  final assigneeId = (wp.assigneeId ?? '').trim();
                                  final avatarUrl = (apiBaseUrl.isNotEmpty && assigneeId.isNotEmpty)
                                      ? '$apiBaseUrl/users/$assigneeId/avatar'
                                      : null;
                                  final statusVs = WorkPackageVisuals.statusVisuals(context, wp.statusName);
                                  final typeVs = WorkPackageVisuals.typeVisuals(context, wp.typeName ?? '—');
                                  final meta = <Widget>[
                                    _buildMetaChip(context, bg: statusVs.$1, fg: statusVs.$2, icon: statusVs.$3, text: wp.statusName),
                                    _buildMetaChip(context, bg: typeVs.$1, fg: typeVs.$2, icon: typeVs.$3, text: wp.typeName ?? '—'),
                                  ];
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
                                      ).then((_) {
                                        if (mounted) _load();
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        if (_recentlyUpdated.isNotEmpty)
                          _buildCollapsibleSection(
                            sectionKey: 'recentlyUpdated',
                            title: 'Son yapılan değişiklikler',
                            titleIcon: Icons.update_rounded,
                            child: Card(
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _recentlyUpdated.length,
                                separatorBuilder: (_, _) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final wp = _recentlyUpdated[index];
                                  final auth = context.read<AuthState>();
                                  final displayName = (wp.assigneeName ?? '').trim();
                                  final apiBaseUrl = (auth.instanceApiBaseUrl ?? '').trim();
                                  final assigneeId = (wp.assigneeId ?? '').trim();
                                  final avatarUrl = (apiBaseUrl.isNotEmpty && assigneeId.isNotEmpty)
                                      ? '$apiBaseUrl/users/$assigneeId/avatar'
                                      : null;
                                  final statusVs = WorkPackageVisuals.statusVisuals(context, wp.statusName);
                                  final typeVs = WorkPackageVisuals.typeVisuals(context, wp.typeName ?? '—');
                                  final meta = <Widget>[
                                    _buildMetaChip(context, bg: statusVs.$1, fg: statusVs.$2, icon: statusVs.$3, text: wp.statusName),
                                    _buildMetaChip(context, bg: typeVs.$1, fg: typeVs.$2, icon: typeVs.$3, text: wp.typeName ?? '—'),
                                  ];
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
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          ...meta,
                                          Text(
                                            'Güncelleme: ${DateFormatters.formatDate(wp.updatedAt)}',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
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
                                      ).then((_) {
                                        if (mounted) _load();
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        if (_showStatusChart && _statusCounts.isNotEmpty)
                          _buildCollapsibleSection(
                            sectionKey: 'statusChart',
                            title: 'Duruma göre dağılım',
                            titleIcon: Icons.pie_chart_rounded,
                            child: _buildChart(
                              context,
                              _statusCounts,
                              theme.colorScheme.primary,
                              _statusChartType,
                            ),
                          ),
                        if (_showTypeChart && _typeCounts.isNotEmpty)
                          _buildCollapsibleSection(
                            sectionKey: 'typeChart',
                            title: 'İş tipine göre dağılım',
                            titleIcon: Icons.category_rounded,
                            child: _buildChart(
                              context,
                              _typeCounts,
                              theme.colorScheme.secondary,
                              _typeChartType,
                            ),
                          ),
                        if (_showTimeSeriesChart && _dueCountByDay.isNotEmpty)
                          _buildCollapsibleSection(
                            sectionKey: 'timeSeries',
                            title: 'Bitiş tarihine göre (önümüzdeki 15 gün)',
                            titleIcon: Icons.show_chart_rounded,
                            child: TimeSeriesChart(
                              data: _dueCountByDay,
                              color: theme.colorScheme.tertiary,
                            ),
                          ),
                        if (_showUpcoming)
                          _buildCollapsibleSection(
                            sectionKey: 'upcoming',
                            title: 'Yaklaşan bitiş tarihleri',
                            titleIcon: Icons.event_rounded,
                            child: _upcoming.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: Text(
                                      'Yaklaşan bitiş tarihi olan iş bulunmuyor.',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  )
                                : Card(
                                    child: ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: _upcoming.length,
                                      separatorBuilder: (_, _) => const Divider(height: 1),
                                      itemBuilder: (context, index) {
                                        final wp = _upcoming[index];
                                        final auth = context.read<AuthState>();
                                        final displayName = (wp.assigneeName ?? '').trim();
                                        final apiBaseUrl = (auth.instanceApiBaseUrl ?? '').trim();
                                        final assigneeId = (wp.assigneeId ?? '').trim();
                                        final avatarUrl = (apiBaseUrl.isNotEmpty && assigneeId.isNotEmpty)
                                            ? '$apiBaseUrl/users/$assigneeId/avatar'
                                            : null;
                                        final statusVs = WorkPackageVisuals.statusVisuals(context, wp.statusName);
                                        final typeVs = WorkPackageVisuals.typeVisuals(context, wp.typeName ?? '—');
                                        final meta = <Widget>[
                                          _buildMetaChip(context, bg: statusVs.$1, fg: statusVs.$2, icon: statusVs.$3, text: wp.statusName),
                                          _buildMetaChip(context, bg: typeVs.$1, fg: typeVs.$2, icon: typeVs.$3, text: wp.typeName ?? '—'),
                                        ];
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
                                          subtitle: Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Wrap(
                                              spacing: 8,
                                              runSpacing: 4,
                                              crossAxisAlignment: WrapCrossAlignment.center,
                                              children: [
                                                ...meta,
                                                Text(
                                                  'Bitiş: ${DateFormatters.formatDate(wp.dueDate)}',
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    color: theme.colorScheme.onSurfaceVariant,
                                                  ),
                                                ),
                                              ],
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
                                            ).then((_) {
                                              if (mounted) _load();
                                            });
                                          },
                                        );
                                      },
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
        ),
    );
  }
}

/// Dashboard üst istatistik satırı (sprint veya açık işler).
class _DashboardStatsRow extends StatelessWidget {
  final Version? activeVersion;
  final int openCount;
  final int totalOpenCount;

  const _DashboardStatsRow({
    required this.activeVersion,
    required this.openCount,
    required this.totalOpenCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (activeVersion != null) ...[
            Expanded(
              child: _DashboardStatCard(
                title: 'Aktif sprint',
                value: activeVersion!.name,
                color: theme.colorScheme.primary,
                valueIsLabel: true,
                icon: Icons.flag_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DashboardStatCard(
                title: 'Sprint\'teki işlerim',
                value: openCount.toString(),
                color: theme.colorScheme.tertiary,
                icon: Icons.assignment_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DashboardStatCard(
                title: 'Bekleyen toplam',
                value: totalOpenCount.toString(),
                color: theme.colorScheme.secondary,
                icon: Icons.inbox_rounded,
              ),
            ),
          ] else ...[
            Expanded(
              child: _DashboardStatCard(
                title: 'Açık işler',
                value: openCount.toString(),
                color: theme.colorScheme.primary,
                icon: Icons.work_rounded,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DashboardStatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final bool valueIsLabel;
  final IconData? icon;

  const _DashboardStatCard({
    required this.title,
    required this.value,
    required this.color,
    this.valueIsLabel = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = color.withValues(alpha: 0.18);
    final onBg = color.withValues(alpha: 0.95);
    return Card(
      elevation: 2,
      shadowColor: color.withValues(alpha: 0.3),
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: onBg),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: onBg.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: valueIsLabel ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: (valueIsLabel ? theme.textTheme.titleSmall : theme.textTheme.titleLarge)?.copyWith(
                color: onBg,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

