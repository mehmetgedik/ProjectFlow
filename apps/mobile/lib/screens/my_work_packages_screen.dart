import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_navigation.dart';
import '../constants/app_strings.dart';
import '../constants/my_work_packages_constants.dart';
import '../mixins/client_context_mixin.dart';
import '../models/query_row.dart';
import '../models/saved_query.dart';
import '../models/work_package.dart';
import '../state/auth_state.dart';
import '../state/pro_state.dart';
import '../utils/app_logger.dart';
import '../utils/date_formatters.dart';
import '../utils/error_messages.dart';
import '../utils/haptic.dart';
import '../widgets/async_content.dart';
import '../widgets/letter_avatar.dart';
import '../widgets/my_work_column_selector.dart';
import '../widgets/my_work_filters_sheet.dart';
import '../widgets/notification_badge_button.dart';
import '../widgets/pro_gate.dart';
import '../widgets/projectflow_logo_button.dart';
import '../widgets/work_package_list_actions.dart';
import '../widgets/small_loading_indicator.dart';
import '../widgets/work_packages_gantt.dart';
import 'time_tracking_screen.dart';
import 'work_package_detail_screen.dart';

enum MyWorkFilter { all, today, overdue }
enum MyWorkSort { dueDateAsc, dueDateDesc }
enum _ViewMode { list, gantt }

class MyWorkPackagesScreen extends StatefulWidget {
  /// Dashboard vb. yerlerden görünümle açıldığında kullanılır.
  final SavedQuery? initialQuery;
  /// Alt navigasyon kabuğu içindeyse true; FAB "Yeni iş paketi" olur.
  final bool isInsideShell;

  const MyWorkPackagesScreen({super.key, this.initialQuery, this.isInsideShell = false});

  @override
  State<MyWorkPackagesScreen> createState() => _MyWorkPackagesScreenState();
}

class _MyWorkPackagesScreenState extends State<MyWorkPackagesScreen> with ClientContextMixin<MyWorkPackagesScreen> {
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  List<WorkPackage> _items = const [];
  List<SavedQuery> _queries = const [];
  SavedQuery? _selectedQuery;
  int _totalCount = 0;
  /// Varsayılan görünümde bir sonraki sayfa offset'i (1 tabanlı).
  int _defaultNextOffset = 1;
  /// Görünüm (query) modunda bir sonraki sayfa offset'i (1 tabanlı).
  int _queryNextOffset = 1;
  /// Kullanıcının seçtiği sayfa boyutu.
  final int _pageSize = MyWorkPackagesConstants.kDefaultPageSize;

  MyWorkFilter _filter = MyWorkFilter.all;
  MyWorkSort _sort = MyWorkSort.dueDateAsc;
  bool _onlyActiveProject = true;
  Set<String> _visibleColumnIds = {'subject', 'status', 'dueDate'};
  /// Kullanıcının eklediği filtreler (OpenProject format: her öğe { alan: { operator, values } }).
  List<Map<String, dynamic>> _userFilters = [];
  /// Kullanıcı filtreleri formdan değiştirildi mi? (query'den gelen filtreleri otomatik override etmemek için)
  bool _userFiltersDirty = false;
  /// Seçili görünümün (query) kendi filtreleri (server tarafı); filtre formunda gösterilir.
  List<Map<String, dynamic>> _queryFilters = [];

  /// Gruplu görünümde kapalı gruplar (anahtar: "$groupBy::$groupLabel").
  final Set<String> _collapsedGroups = <String>{};
  /// Hiyerarşik görünümde kapalı düğümler (parent wp.id).
  final Set<String> _collapsedNodes = <String>{};
  bool _sideActionsCollapsed = false;
  _ViewMode _viewMode = _ViewMode.list;
  GanttDateSource _ganttDateSource = GanttDateSource.startDue;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _selectedQuery = widget.initialQuery;
    }
    _load();
    _loadQueries();
  }

  Future<void> _loadQueries() async {
    try {
      final auth = context.read<AuthState>();
      final client = auth.client;
      if (client == null) return;
      final projectId = _onlyActiveProject ? auth.activeProject?.id : null;
      final list = await client.getQueries(projectId: projectId);
      if (mounted) setState(() => _queries = list);
    } catch (e) {
      if (kDebugMode) AppLogger.logError('Görünüm listesi yüklenemedi', error: e);
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthState>();
      final client = auth.client;
      if (client == null) throw Exception('Oturum bulunamadı.');
      final normalizedFilters = _normalizeFilters(_userFilters);
      if (_selectedQuery != null) {
        final result = await client.getQueryWithResults(
          _selectedQuery!.id,
          pageSize: _pageSize,
          offset: 1,
          // Kullanıcı filtreleri formdan değiştirildiyse override et; yoksa görünümün kendi filtreleri çalışsın.
          overrideFilters: (_userFiltersDirty && normalizedFilters.isNotEmpty) ? normalizedFilters : null,
        );
        _items = result.workPackages;
        _totalCount = result.total;
        _queryNextOffset = 2;
        // API'den dönen tam sorguyu kullan (filtre, sıralama, gruplama web'deki gibi).
        _selectedQuery = result.query;
        // Görünümün filtrelerini formda göster (ama kullanıcı değiştirmediyse override göndermeyiz).
        _queryFilters = _normalizeFilters(List<Map<String, dynamic>>.from(result.query.apiFilters));
        if (!_userFiltersDirty) {
          // Varsayılan olarak override yok: görünüm filtresi server'da uygulanır.
          _userFilters = [];
        }
        if (_visibleColumnIds.isNotEmpty && result.query.columns.isNotEmpty) {
          _visibleColumnIds = result.query.columns.map((c) => c.id).where((id) => id != 'assignee').toSet();
          if (_visibleColumnIds.isEmpty) _visibleColumnIds = {'subject', 'status', 'dueDate'};
        }
      } else {
        final projectId = _onlyActiveProject ? auth.activeProject?.id : null;
        final result = await client.getMyOpenWorkPackages(
          projectId: projectId,
          pageSize: _pageSize,
          offset: 1,
          extraFilters: normalizedFilters.isEmpty ? null : normalizedFilters,
        );
        _items = result.workPackages;
        _totalCount = result.total;
        _defaultNextOffset = 2;
      }
    } catch (e, st) {
      AppLogger.logError('MyWorkPackages load failed', error: e);
      if (kDebugMode) debugPrintStack(stackTrace: st);
      if (e is TimeoutException) {
        _error = AppStrings.errorTimeoutDefault;
      } else {
        _error = ErrorMessages.userFriendly(e);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Varsayılan görünümde bir sonraki sayfayı yükleyip listeye ekler (P0-F03).
  Future<void> _loadMore() async {
    if (_selectedQuery != null || _loadingMore) return;
    if (_items.length >= _totalCount) return;
    setState(() => _loadingMore = true);
    try {
      final auth = context.read<AuthState>();
      final client = auth.client;
      if (client == null) return;
      final projectId = _onlyActiveProject ? auth.activeProject?.id : null;
      final result = await client.getMyOpenWorkPackages(
        projectId: projectId,
        pageSize: _pageSize,
        offset: _defaultNextOffset,
      );
      if (mounted) {
        setState(() {
          _items = [..._items, ...result.workPackages];
          _defaultNextOffset++;
          _loadingMore = false;
        });
      }
    } catch (e) {
      if (kDebugMode) AppLogger.logError('Daha fazla iş yüklenemedi', error: e);
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  /// Varsayılan görünümde daha fazla sayfa yüklenebilir mi (P0-F03).
  bool get _showLoadMore =>
      _selectedQuery == null && _items.length < _totalCount && !_loading;

  /// Görünüm (query) modunda daha fazla sayfa yüklenebilir mi.
  bool get _showLoadMoreQuery =>
      _selectedQuery != null && _items.length < _totalCount && !_loading && !_loadingMore;

  Future<void> _loadMoreQuery() async {
    if (_selectedQuery == null || _loadingMore) return;
    if (_items.length >= _totalCount) return;
    mediumImpact();
    setState(() => _loadingMore = true);
    try {
      final c = client;
      if (c == null) return;
      final normalizedFilters = _normalizeFilters(_userFilters);
      final result = await c.getQueryWithResults(
        _selectedQuery!.id,
        pageSize: _pageSize,
        offset: _queryNextOffset,
        overrideFilters: (_userFiltersDirty && normalizedFilters.isNotEmpty) ? normalizedFilters : null,
      );
      if (mounted) {
        setState(() {
          _items = [..._items, ...result.workPackages];
          _queryNextOffset++;
          _loadingMore = false;
        });
      }
    } catch (e) {
      if (kDebugMode) AppLogger.logError('Görünüm sonraki sayfa yüklenemedi', error: e);
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  List<WorkPackage> get _visibleItems {
    if (_selectedQuery != null) return _items;
    Iterable<WorkPackage> list = _items;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_filter == MyWorkFilter.today) {
      list = list.where((wp) {
        final d = wp.dueDate;
        if (d == null) return false;
        final dd = DateTime(d.year, d.month, d.day);
        return dd == today;
      });
    } else if (_filter == MyWorkFilter.overdue) {
      list = list.where((wp) {
        final d = wp.dueDate;
        if (d == null) return false;
        final dd = DateTime(d.year, d.month, d.day);
        return dd.isBefore(today);
      });
    }
    final sorted = List<WorkPackage>.from(list);
    sorted.sort((a, b) {
      final ad = a.dueDate;
      final bd = b.dueDate;
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      final cmp = ad.compareTo(bd);
      return _sort == MyWorkSort.dueDateAsc ? cmp : -cmp;
    });
    return sorted;
  }

  void _changeFilter(MyWorkFilter filter) {
    setState(() => _filter = filter);
  }

  Future<void> _openViewSheet() async {
    final chosen = await showModalBottomSheet<SavedQuery?>(
      context: context,
      useSafeArea: true,
      builder: (context) {
        final theme = Theme.of(context);
        final maxH = MediaQuery.of(context).size.height * 0.6;
        final visibleQueries = _queries.where((q) => !q.hidden).toList();
        final sortedQueries = List<SavedQuery>.from(visibleQueries)
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxH),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ListTile(
                    title: Text('Görünüm'),
                    subtitle: Text('OpenProject\'te kayıtlı görünüm veya varsayılan liste'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Varsayılan (açık işlerim)'),
                    selected: _selectedQuery == null,
                    onTap: () => Navigator.pop(context, null),
                  ),
                  ...sortedQueries.map((q) {
                    final isGlobal = q.projectId == null;
                    return ListTile(
                      leading: q.starred
                          ? Icon(Icons.star_rounded, size: 22, color: theme.colorScheme.primary)
                          : const SizedBox(width: 22, height: 22),
                      title: Text(q.name),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isGlobal
                                    ? theme.colorScheme.tertiaryContainer
                                    : theme.colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                isGlobal ? 'Global görünüm' : 'Proje görünümü',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: isGlobal
                                      ? theme.colorScheme.onTertiaryContainer
                                      : theme.colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                            if (q.starred)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star_rounded, size: 14, color: theme.colorScheme.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Favori',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      selected: _selectedQuery?.id == q.id,
                      onTap: () => Navigator.pop(context, q),
                    );
                  }),
                  if (_queries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Kayıtlı görünüm bulunamadı.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (chosen != null || (_selectedQuery != null && chosen == null)) {
      setState(() {
        _selectedQuery = chosen;
        _collapsedGroups.clear();
        _collapsedNodes.clear();
        if (chosen == null) {
          // Varsayılan görünüme dönünce kullanıcı filtrelerini koru (isterse filtre formundan temizler).
          _queryFilters = [];
        } else {
          // Görünümden gelen filtreleri formda göster (kullanıcı değiştirirse override edilir).
          _queryFilters = _normalizeFilters(List<Map<String, dynamic>>.from(chosen.apiFilters));
          _userFilters = [];
          _userFiltersDirty = false;
          if (chosen.columns.isNotEmpty) {
            _visibleColumnIds = chosen.columns.map((c) => c.id).where((id) => id != 'assignee').toSet();
            if (_visibleColumnIds.isEmpty) _visibleColumnIds = {'subject', 'status', 'dueDate'};
          }
        }
      });
      _load();
    }
  }

  Future<void> _openSortSheet() async {
    final selected = await showModalBottomSheet<MyWorkSort>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.35,
          maxChildSize: 0.6,
          minChildSize: 0.25,
          expand: false,
          builder: (context, scrollController) => SafeArea(
            child: ListView(
              controller: scrollController,
              shrinkWrap: true,
              children: [
                const ListTile(title: Text('Sırala')),
                RadioGroup<MyWorkSort>(
                  groupValue: _sort,
                  onChanged: (v) => Navigator.pop(context, v),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile<MyWorkSort>(
                        value: MyWorkSort.dueDateAsc,
                        title: const Text('Bitiş tarihi ↑ (en yakın önce)'),
                      ),
                      RadioListTile<MyWorkSort>(
                        value: MyWorkSort.dueDateDesc,
                        title: const Text('Bitiş tarihi ↓ (en geç önce)'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      setState(() => _sort = selected);
    }
  }

  Future<void> _openColumnsSheet() async {
    final initial = Set<String>.from(_visibleColumnIds)..remove('assignee');
    await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      builder: (context) => MyWorkColumnSelector(
        initialSelected: initial,
        onApply: (selected) {
          if (selected.isNotEmpty) {
            setState(() => _visibleColumnIds = selected..remove('assignee'));
          }
          Navigator.pop(context, true);
        },
      ),
    );
  }

  /// OpenProject API filtre formatını normalize eder:
  /// - values her zaman string listesi olur
  /// - değer gerektirmeyen operatörlerde values boş olur
  static List<Map<String, dynamic>> _normalizeFilters(List<Map<String, dynamic>> input) {
    final result = <Map<String, dynamic>>[];
    for (final f in input) {
      if (f.isEmpty) continue;
      final entry = f.entries.first;
      final field = entry.key.toString().trim();
      if (field.isEmpty) continue;

      final raw = entry.value;
      if (raw is! Map) continue;
      final op = raw['operator']?.toString() ?? '=';

      List<String> values = <String>[];
      if (MyWorkPackagesConstants.operatorNeedsValues(op)) {
        final rawValues = raw['values'];
        if (rawValues is List) {
          values = rawValues
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList(growable: false);
        } else if (rawValues != null) {
          final v = rawValues.toString().trim();
          if (v.isNotEmpty) values = [v];
        }
      }

      result.add({
        field: {'operator': op, 'values': values},
      });
    }
    return result;
  }

  Future<void> _openFilterSheet() async {
    final source = (_selectedQuery != null && !_userFiltersDirty) ? _queryFilters : _userFilters;
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => MyWorkFiltersSheet(
        initialFilters: source,
        onApply: (newFilters) {
          setState(() {
            _userFilters = newFilters;
            _userFiltersDirty = true;
          });
          _load();
        },
      ),
    );
  }

  /// Kullanıcı görünümü daraltmış mı (kayıtlı görünüm, filtre, form filtreleri veya sadece aktif proje).
  bool get _hasNarrowedView =>
      _selectedQuery != null ||
      _filter != MyWorkFilter.all ||
      _userFilters.isNotEmpty ||
      _onlyActiveProject;

  String get _filterSortSummary {
    final viewLabel = _selectedQuery != null ? _selectedQuery!.name : 'Varsayılan';
    final countLabel = _totalCount > 0 ? '$_totalCount kayıt' : '';
    if (_selectedQuery != null) {
      final q = _selectedQuery!;
      final parts = <String>[viewLabel];
      if (countLabel.isNotEmpty) parts.add(countLabel);
      // Görünüm filtreleri metin olarak yazılmaz; filtre formunda düzenlenir.
      if (_userFilters.isNotEmpty) parts.add('Filtre: ${_userFilters.length}');
      if (q.sortByTitles.isNotEmpty) {
        parts.add('Sıra: ${q.sortByTitles.join(', ')}');
      }
      if (q.groupBy != null && q.groupBy!.isNotEmpty) {
        parts.add('Grup: ${q.groupBy}');
      }
      if (q.showHierarchies) parts.add('Hiyerarşi');
      return parts.join(' · ');
    }
    final filterLabel = switch (_filter) {
      MyWorkFilter.all => 'Açık işlerim',
      MyWorkFilter.today => 'Bugün bitiş',
      MyWorkFilter.overdue => 'Gecikmiş',
    };
    final sortLabel = _sort == MyWorkSort.dueDateAsc ? 'Bitiş tarihi ↑' : 'Bitiş tarihi ↓';
    final scopeLabel = _onlyActiveProject ? 'Bu proje' : 'Tüm projeler';
    final parts = [filterLabel, sortLabel, scopeLabel];
    if (_userFilters.isNotEmpty) parts.add('Filtre: ${_userFilters.length}');
    return parts.join(' · ');
  }

  String _cellText(WorkPackage wp, String columnId) {
    switch (columnId) {
      case 'id': return wp.id;
      case 'subject': return wp.subject;
      case 'type': return wp.typeName ?? '';
      case 'status': return wp.statusName;
      case 'priority': return wp.priorityName ?? '';
      case 'assignee': return wp.assigneeName ?? '';
      case 'dueDate': return wp.dueDate != null ? DateFormatters.formatDate(wp.dueDate) : '';
      case 'updated_at': return wp.updatedAt != null ? DateFormatters.formatDate(wp.updatedAt) : '';
      default: return '';
    }
  }

  /// Liste satırı leading: atanan kullanıcı avatar'ı. Atanan yoksa silik varsayılan kullanıcı ikonu.
  Widget? _buildRowLeadingAvatar(BuildContext context, WorkPackage wp) {
    final auth = context.read<AuthState>();
    final displayName = (wp.assigneeName ?? '').trim();
    final theme = Theme.of(context);

    if (displayName.isEmpty) {
      return SizedBox(
        width: 40,
        height: 40,
        child: Material(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          shape: const CircleBorder(),
          child: Icon(
            Icons.person_rounded,
            size: 24,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    final apiBaseUrl = (auth.instanceApiBaseUrl ?? '').trim();
    final assigneeId = (wp.assigneeId ?? '').trim();
    final avatarUrl = (apiBaseUrl.isNotEmpty && assigneeId.isNotEmpty)
        ? '$apiBaseUrl/users/$assigneeId/avatar'
        : null;
    return LetterAvatar(
      displayName: displayName,
      imageUrl: avatarUrl,
      imageHeaders: avatarUrl != null ? auth.authHeadersForInstanceImages : null,
      size: 40,
    );
  }

  /// Duruma göre renk ve ikon belirler (modern rounded ikonlar).
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

  /// İş tipi için renk ve ikon (modern rounded).
  (Color bg, Color fg, IconData icon) _typeVisuals(BuildContext context, String type) {
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

  /// Öncelik için renk ve ikon.
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
      return (theme.colorScheme.surfaceContainerHighest, theme.colorScheme.onSurfaceVariant, Icons.low_priority_rounded);
    }
    return (theme.colorScheme.surfaceContainerHighest, theme.colorScheme.onSurfaceVariant, Icons.flag_rounded);
  }

  /// İş satırında uzun basınca açılan menü: Zaman ekle / İş detayına git.
  void _showWorkPackageContextSheet(BuildContext context, WorkPackage wp) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                '#${wp.id} · ${wp.subject}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ListTile(
              leading: Icon(Icons.schedule_rounded, color: Theme.of(context).colorScheme.primary),
              title: const Text('Zaman ekle'),
              subtitle: const Text('Bu iş için zaman kaydı oluştur'),
              onTap: () {
                Navigator.of(ctx).pop();
                lightImpact();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TimeTrackingScreen(initialWorkPackageForTime: wp),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.open_in_new_rounded, color: Theme.of(context).colorScheme.primary),
              title: const Text('İş detayına git'),
              subtitle: const Text('İş paketini aç'),
              onTap: () {
                Navigator.of(ctx).pop();
                lightImpact();
                NavHelpers.toWorkPackageDetail(context, wp).then((_) {
                  if (mounted) _load();
                });
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Query modunda (seçili görünüm) kullanılacak satır modeli: grup başlığı veya iş paketi + hiyerarşik seviye.
  List<QueryRow> _buildQueryRows() {
    if (_selectedQuery == null) {
      return _visibleItems.map((wp) => QueryRow.workPackage(wp)).toList();
    }
    final q = _selectedQuery!;
    if (q.groupBy != null && q.groupBy!.isNotEmpty) {
      return _buildGroupedRows(q.groupBy!);
    }
    if (q.showHierarchies) {
      return _buildHierarchyRows();
    }
    return _items.map((wp) => QueryRow.workPackage(wp)).toList();
  }

  List<QueryRow> _buildHierarchyRows() {
    final byId = <String, WorkPackage>{for (final wp in _items) wp.id: wp};
    final childrenOf = <String, List<WorkPackage>>{};
    for (final wp in _items) {
      final parentId = wp.parentId;
      if (parentId != null && parentId.isNotEmpty && byId.containsKey(parentId)) {
        childrenOf.putIfAbsent(parentId, () => []).add(wp);
      }
    }
    final visited = <String>{};
    final rows = <QueryRow>[];

    void visit(WorkPackage wp, int depth) {
      if (visited.contains(wp.id)) return;
      visited.add(wp.id);
      final kids = childrenOf[wp.id] ?? const [];
      final hasChildren = kids.isNotEmpty;
      rows.add(QueryRow.workPackage(wp, depth: depth, hasChildren: hasChildren));
      if (hasChildren && _collapsedNodes.contains(wp.id)) return;
      for (final c in kids) {
        visit(c, depth + 1);
      }
    }

    // Kökler: parentId olmayan veya parent'ı listede olmayanlar.
    for (final wp in _items) {
      final parentId = wp.parentId;
      final isRoot = parentId == null || parentId.isEmpty || !byId.containsKey(parentId);
      if (isRoot) {
        visit(wp, 0);
      }
    }
    // Her ihtimale karşı ziyaret edilmemiş kalanları da ekle.
    for (final wp in _items) {
      if (!visited.contains(wp.id)) {
        visit(wp, 0);
      }
    }
    return rows;
  }

  List<QueryRow> _buildGroupedRows(String groupBy) {
    String keyFor(WorkPackage wp) {
      switch (groupBy) {
        case 'status':
          return wp.statusName;
        case 'type':
          return wp.typeName ?? 'Belirtilmemiş';
        case 'assignee':
          return wp.assigneeName ?? 'Atanmamış';
        case 'priority':
          return wp.priorityName ?? 'Belirtilmemiş';
        case 'project':
          return wp.projectId ?? 'Belirtilmemiş';
        default:
          return '';
      }
    }

    final groups = <String, List<WorkPackage>>{};
    for (final wp in _items) {
      final key = keyFor(wp);
      groups.putIfAbsent(key, () => []).add(wp);
    }

    final rows = <QueryRow>[];
    final keys = groups.keys.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    for (final key in keys) {
      rows.add(QueryRow.groupHeader(key));
      final groupKey = '$groupBy::$key';
      if (_collapsedGroups.contains(groupKey)) continue;
      for (final wp in groups[key]!) {
        rows.add(QueryRow.workPackage(wp));
      }
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final isPro = context.watch<ProState>().isPro;
    final projectName = auth.activeProject?.name ?? 'Benim işlerim';
    final items = _visibleItems;

    // Kayıtlı görünüm (query) ile açıldıysa ve Pro değilse: form açılışında da Pro kilidi göster.
    if (widget.initialQuery != null && !isPro) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.initialQuery!.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Geri',
          ),
        ),
        body: ProGate(
          message: 'Kayıtlı görünümler Pro özelliğidir. Kullanmak için Pro\'ya yükseltin.',
          child: const SizedBox.shrink(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          projectName,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        actions: [
          if (!widget.isInsideShell)
            Tooltip(
              message: 'Yeni iş paketi oluştur',
              waitDuration: const Duration(milliseconds: 500),
              showDuration: const Duration(seconds: 2),
              child: IconButton(
                onPressed: () {
                  mediumImpact();
                  NavHelpers.toCreateWorkPackage(context, onPopped: _load);
                },
                tooltip: 'Yeni iş paketi oluştur',
                icon: const Icon(Icons.add_rounded, size: 24),
              ),
            ),
          Tooltip(
            message: 'Listeyi yenile',
            waitDuration: const Duration(milliseconds: 500),
            showDuration: const Duration(seconds: 2),
            child: IconButton(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 22),
              tooltip: 'Listeyi yenile',
            ),
          ),
          const ProjectFlowLogoButton(),
          const NotificationBadgeButton(iconSize: 22),
        ],
      ),
      floatingActionButton: widget.isInsideShell
          ? Tooltip(
              message: 'Yeni iş paketi oluştur',
              waitDuration: const Duration(milliseconds: 500),
              showDuration: const Duration(seconds: 2),
              child: FloatingActionButton.small(
                heroTag: 'my_work_add',
                onPressed: () {
                  mediumImpact();
                  NavHelpers.toCreateWorkPackage(context, onPopped: _load);
                },
                child: const Icon(Icons.add_rounded, size: 20),
              ),
            )
          : Tooltip(
              message: 'Listeyi yenile',
              waitDuration: const Duration(milliseconds: 500),
              showDuration: const Duration(seconds: 2),
              child: FloatingActionButton.small(
                heroTag: 'my_work_refresh',
                onPressed: () {
                  mediumImpact();
                  _load();
                },
                child: const Icon(Icons.refresh_rounded, size: 20),
              ),
            ),
      body: AsyncContent(
        loading: _loading,
        error: _error,
        onRetry: _load,
        errorTrailing: _hasNarrowedView
            ? TextButton(
                onPressed: () {
                  setState(() {
                    _selectedQuery = null;
                    _filter = MyWorkFilter.all;
                    _userFilters = [];
                    _userFiltersDirty = false;
                    _onlyActiveProject = false;
                    _error = null;
                  });
                  _load();
                },
                child: const Text('Varsayılan görünüme dön'),
              )
            : null,
        empty: _EmptyWorkPackagesContent(),
        emptyTrailing: _hasNarrowedView
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedQuery = null;
                        _filter = MyWorkFilter.all;
                        _userFilters = [];
                        _userFiltersDirty = false;
                        _onlyActiveProject = false;
                      });
                      _load();
                    },
                    icon: const Icon(Icons.view_list_rounded, size: 20),
                    label: const Text('Varsayılan görünüme dön'),
                  ),
                  if (_userFilters.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _userFilters = [];
                          _userFiltersDirty = false;
                        });
                        _load();
                      },
                      icon: const Icon(Icons.filter_alt_off_rounded, size: 20),
                      label: const Text('Filtreleri temizle'),
                    ),
                  ],
                ],
              )
            : null,
        showEmpty: items.isEmpty,
        child: Stack(
                      children: [
                        Column(
                          children: [
                            _MyWorkPackagesFilterBar(
                              selectedQuery: _selectedQuery,
                              filter: _filter,
                              onlyActiveProject: _onlyActiveProject,
                              viewMode: _viewMode,
                              ganttDateSource: _ganttDateSource,
                              filterSortSummary: _filterSortSummary,
                              onFilterAll: () => _changeFilter(MyWorkFilter.all),
                              onFilterToday: () => _changeFilter(MyWorkFilter.today),
                              onFilterOverdue: () => _changeFilter(MyWorkFilter.overdue),
                              onOnlyActiveProject: () {
                                setState(() => _onlyActiveProject = !_onlyActiveProject);
                                _load();
                                _loadQueries();
                              },
                              onViewList: () {
                                mediumImpact();
                                setState(() => _viewMode = _ViewMode.list);
                              },
                              onViewGantt: () {
                                mediumImpact();
                                setState(() => _viewMode = _ViewMode.gantt);
                              },
                              onGanttStartDue: () {
                                mediumImpact();
                                setState(() => _ganttDateSource = GanttDateSource.startDue);
                              },
                              onGanttUpdatedAt: () {
                                mediumImpact();
                                setState(() => _ganttDateSource = GanttDateSource.updatedAt);
                              },
                            ),
                        const Divider(height: 1),
                        Expanded(
                          child: _viewMode == _ViewMode.gantt
                              ? WorkPackagesGantt(
                                  items: _visibleItems,
                                  dateSource: _ganttDateSource,
                                  onRefresh: _load,
                                )
                              : RefreshIndicator(
                                  onRefresh: _load,
                                  child: ListView.separated(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    cacheExtent: 300,
                                    itemCount: _selectedQuery != null
                                        ? _buildQueryRows().length + (_showLoadMoreQuery ? 1 : 0)
                                        : items.length + (_showLoadMore ? 1 : 0),
                                    separatorBuilder: (_, _) => const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                if (_selectedQuery == null && _showLoadMore && index == items.length) {
                                  return ListTile(
                                    title: Center(
                                      child: _loadingMore
                                          ? const Padding(
                                              padding: EdgeInsets.symmetric(vertical: 12),
                                              child: SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: SmallLoadingIndicator(),
                                              ),
                                            )
                                          : IconButton(
                                              onPressed: _loadMore,
                                              icon: const Icon(Icons.add_circle_outline_rounded, size: 32),
                                              tooltip: 'Daha fazla yükle',
                                            ),
                                    ),
                                  );
                                }

                                if (_selectedQuery != null) {
                                  final rows = _buildQueryRows();
                                  if (_showLoadMoreQuery && index == rows.length) {
                                    return ListTile(
                                      title: Center(
                                        child: _loadingMore
                                            ? const Padding(
                                                padding: EdgeInsets.symmetric(vertical: 12),
                                                child: SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child: SmallLoadingIndicator(),
                                                ),
                                              )
                                            : IconButton(
                                                onPressed: _loadMoreQuery,
                                                icon: const Icon(Icons.add_circle_outline_rounded, size: 32),
                                                tooltip: 'Sonraki sayfayı yükle (daha fazla iş göster)',
                                              ),
                                      ),
                                    );
                                  }
                                  final row = rows[index];
                                  if (row.isGroupHeader) {
                                    final groupBy = _selectedQuery?.groupBy ?? '';
                                    final label = row.groupLabel ?? '';
                                    final groupKey = '$groupBy::$label';
                                    final collapsed = _collapsedGroups.contains(groupKey);
                                    return KeyedSubtree(
                                      key: ValueKey<String>('gh::$groupKey'),
                                      child: Material(
                                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            if (collapsed) {
                                              _collapsedGroups.remove(groupKey);
                                            } else {
                                              _collapsedGroups.add(groupKey);
                                            }
                                          });
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          child: Row(
                                            children: [
                                              Icon(
                                                collapsed ? Icons.chevron_right_rounded : Icons.expand_more_rounded,
                                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  label,
                                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                        fontWeight: FontWeight.w600,
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
                                  final wp = row.workPackage!;
                                  // Her satır kendi iş paketinin atananını gösterir (parent/child karışması önlenir).
                                  final meta = <Widget>[];
                                  for (final id in _visibleColumnIds) {
                                    if (id == 'subject') continue;
                                    final text = _cellText(wp, id);
                                    if (text.isEmpty && id != 'id') continue;
                                    if (id == 'status') {
                                      final (bg, fg, icon) = _statusVisuals(context, text);
                                      meta.add(Container(
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
                                              text,
                                              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
                                            ),
                                          ],
                                        ),
                                      ));
                                    } else if (id == 'type') {
                                      final (bg, fg, icon) = _typeVisuals(context, text);
                                      meta.add(Container(
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
                                              text,
                                              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
                                            ),
                                          ],
                                        ),
                                      ));
                                    } else if (id == 'priority') {
                                      final (bg, fg, icon) = _priorityVisuals(context, text);
                                      meta.add(Container(
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
                                              text,
                                              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
                                            ),
                                          ],
                                        ),
                                      ));
                                    } else if (id == 'assignee') {
                                      final displayName = (wp.assigneeName ?? 'Atanmamış').trim();
                                      final assigneeId = (wp.assigneeId ?? '').trim();
                                      final auth = context.read<AuthState>();
                                      final apiBaseUrl = auth.instanceApiBaseUrl ?? '';
                                      final avatarUrl = (apiBaseUrl.isNotEmpty && assigneeId.isNotEmpty)
                                          ? '$apiBaseUrl/users/$assigneeId/avatar'
                                          : null;
                                      meta.add(Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          LetterAvatar(
                                            displayName: displayName.isEmpty ? '—' : displayName,
                                            imageUrl: avatarUrl,
                                            imageHeaders: avatarUrl != null ? auth.authHeadersForInstanceImages : null,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            wp.assigneeName ?? 'Atanmamış',
                                            style: Theme.of(context).textTheme.bodySmall,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ],
                                      ));
                                    } else {
                                      final label = MyWorkPackagesConstants.kColumnLabels[id] ?? id;
                                      meta.add(Text(
                                        id == 'subject' ? text : '$label: $text',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ));
                                    }
                                  }
                                  if (wp.parentId != null &&
                                      wp.parentId!.isNotEmpty &&
                                      !(_selectedQuery?.showHierarchies ?? false)) {
                                    // Hiyerarşi kapalıysa bile parent bilgisi küçük bir chip ile gösterilebilir.
                                    meta.insert(
                                      0,
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.account_tree_rounded,
                                              size: 14,
                                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '#${wp.parentId}',
                                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                  final indent = row.depth * 16.0;
                                  final isParent = row.hasChildren;
                                  final tileColor = isParent
                                      ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                                      : null;
                                  return KeyedSubtree(
                                    key: ValueKey<String>('wp::${wp.id}'),
                                    child: ListTile(
                                    tileColor: tileColor,
                                    leading: KeyedSubtree(
                                      key: ValueKey<String>('avatar::${wp.id}'),
                                      child: _buildRowLeadingAvatar(context, wp) ?? const SizedBox(width: 40, height: 40),
                                    ),
                                    contentPadding:
                                        EdgeInsets.only(left: 16 + indent, right: 16, top: 4, bottom: 4),
                                    trailing: row.hasChildren
                                        ? IconButton(
                                            tooltip: _collapsedNodes.contains(wp.id) ? 'Alt işleri göster (genişlet)' : 'Alt işleri gizle (daralt)',
                                            icon: Icon(
                                              _collapsedNodes.contains(wp.id)
                                                  ? Icons.chevron_right_rounded
                                                  : Icons.expand_more_rounded,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                if (_collapsedNodes.contains(wp.id)) {
                                                  _collapsedNodes.remove(wp.id);
                                                } else {
                                                  _collapsedNodes.add(wp.id);
                                                }
                                              });
                                            },
                                          )
                                        : null,
                                    title: Text(
                                      wp.subject,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    subtitle: meta.isEmpty
                                        ? null
                                        : Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Wrap(
                                              spacing: 8,
                                              runSpacing: 4,
                                              crossAxisAlignment: WrapCrossAlignment.center,
                                              children: meta,
                                            ),
                                          ),
                                    onTap: () {
                                      lightImpact();
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => WorkPackageDetailScreen(workPackage: wp),
                                        ),
                                      ).then((_) {
                                        if (mounted) _load();
                                      });
                                    },
                                    onLongPress: () {
                                      mediumImpact();
                                      _showWorkPackageContextSheet(context, wp);
                                    },
                                  ),
                                  );
                                }

                                final wp = items[index];
                              final meta = <Widget>[];
                              for (final id in _visibleColumnIds) {
                                if (id == 'subject') continue;
                                final text = _cellText(wp, id);
                                if (text.isEmpty && id != 'id') continue;
                                if (id == 'status') {
                                  final (bg, fg, icon) = _statusVisuals(context, text);
                                  meta.add(Container(
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
                                          text,
                                          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
                                        ),
                                      ],
                                    ),
                                  ));
                                } else if (id == 'type') {
                                  final (bg, fg, icon) = _typeVisuals(context, text);
                                  meta.add(Container(
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
                                          text,
                                          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
                                        ),
                                      ],
                                    ),
                                  ));
                                } else if (id == 'priority') {
                                  final (bg, fg, icon) = _priorityVisuals(context, text);
                                  meta.add(Container(
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
                                          text,
                                          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
                                        ),
                                      ],
                                    ),
                                  ));
                                } else if (id == 'assignee') {
                                  final displayName = (wp.assigneeName ?? 'Atanmamış').trim();
                                  final assigneeId = (wp.assigneeId ?? '').trim();
                                  final auth = context.read<AuthState>();
                                  final apiBaseUrl = auth.instanceApiBaseUrl ?? '';
                                  final avatarUrl = (apiBaseUrl.isNotEmpty && assigneeId.isNotEmpty)
                                      ? '$apiBaseUrl/users/$assigneeId/avatar'
                                      : null;
                                  meta.add(Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      LetterAvatar(
                                        displayName: displayName.isEmpty ? '—' : displayName,
                                        imageUrl: avatarUrl,
                                        imageHeaders: avatarUrl != null ? auth.authHeadersForInstanceImages : null,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        wp.assigneeName ?? 'Atanmamış',
                                        style: Theme.of(context).textTheme.bodySmall,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ],
                                  ));
                                } else {
                                  final label = MyWorkPackagesConstants.kColumnLabels[id] ?? id;
                                  meta.add(Text(
                                    id == 'subject' ? text : '$label: $text',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ));
                                }
                              }
                              if (wp.parentId != null && wp.parentId!.isNotEmpty) {
                                meta.insert(
                                  0,
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.account_tree_rounded,
                                          size: 14,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '#${wp.parentId}',
                                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              return KeyedSubtree(
                                key: ValueKey<String>('wp::${wp.id}'),
                                child: ListTile(
                                leading: KeyedSubtree(
                                  key: ValueKey<String>('avatar::${wp.id}'),
                                  child: _buildRowLeadingAvatar(context, wp) ?? const SizedBox(width: 40, height: 40),
                                ),
                                title: Text(
                                  wp.subject,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                subtitle: meta.isEmpty
                                    ? null
                                    : Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: meta,
                                        ),
                                      ),
                                onTap: () {
                                  lightImpact();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => WorkPackageDetailScreen(workPackage: wp),
                                    ),
                                  ).then((_) {
                                    if (mounted) _load();
                                  });
                                },
                                onLongPress: () {
                                  mediumImpact();
                                  _showWorkPackageContextSheet(context, wp);
                                },
                              ),
                              );
                            },
                          ),
                        ),
                        ),
                        // Kayıt sayısı AppBar başlığında gösteriliyor.
                          ],
                        ),

                        // Sağ tarafta sticky aksiyon ikonları (Görünüm/Sırala/Filtre/Kolonlar/Yenile)
                        Positioned(
                          right: 10,
                          top: 92,
                          bottom: 18,
                          child: StickySideActions(
                            collapsed: _sideActionsCollapsed,
                            onToggleCollapsed: () {
                              setState(() => _sideActionsCollapsed = !_sideActionsCollapsed);
                            },
                            showSort: _selectedQuery == null,
                            hasFilters: _userFilters.isNotEmpty,
                            onOpenViews: _openViewSheet,
                            onOpenSort: _openSortSheet,
                            onOpenFilters: _openFilterSheet,
                            onOpenColumns: _openColumnsSheet,
                            onRefresh: _load,
                            isPro: context.watch<ProState>().isPro,
                            onProRequired: () {
                              Navigator.of(context).pushNamed(AppRoutes.proUpgrade);
                            },
                          ),
                        ),
                      ],
                    ),
      ),
    );
  }
}

/// Boş iş listesi görünümü (üzerine atanmış açık iş yok).
class _EmptyWorkPackagesContent extends StatelessWidget {
  const _EmptyWorkPackagesContent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          Text(
            'Üzerine atanmış açık iş bulunamadı.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Benim işlerim ekranında filtre ve görünüm çubuğu (varsayılan/gantt, aktif proje, özet metni).
class _MyWorkPackagesFilterBar extends StatelessWidget {
  final SavedQuery? selectedQuery;
  final MyWorkFilter filter;
  final bool onlyActiveProject;
  final _ViewMode viewMode;
  final GanttDateSource ganttDateSource;
  final String filterSortSummary;
  final VoidCallback onFilterAll;
  final VoidCallback onFilterToday;
  final VoidCallback onFilterOverdue;
  final VoidCallback onOnlyActiveProject;
  final VoidCallback onViewList;
  final VoidCallback onViewGantt;
  final VoidCallback onGanttStartDue;
  final VoidCallback onGanttUpdatedAt;

  const _MyWorkPackagesFilterBar({
    required this.selectedQuery,
    required this.filter,
    required this.onlyActiveProject,
    required this.viewMode,
    required this.ganttDateSource,
    required this.filterSortSummary,
    required this.onFilterAll,
    required this.onFilterToday,
    required this.onFilterOverdue,
    required this.onOnlyActiveProject,
    required this.onViewList,
    required this.onViewGantt,
    required this.onGanttStartDue,
    required this.onGanttUpdatedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (selectedQuery == null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilterIconButton(
                  icon: Icons.filter_list_rounded,
                  selectedIcon: Icons.filter_list_rounded,
                  tooltip: 'Tüm açık işlerimi göster',
                  selected: filter == MyWorkFilter.all,
                  onPressed: onFilterAll,
                ),
                const SizedBox(width: 4),
                FilterIconButton(
                  icon: Icons.today_outlined,
                  selectedIcon: Icons.today_rounded,
                  tooltip: 'Bugün bitiş tarihli işler',
                  selected: filter == MyWorkFilter.today,
                  onPressed: onFilterToday,
                ),
                const SizedBox(width: 4),
                FilterIconButton(
                  icon: Icons.event_busy_outlined,
                  selectedIcon: Icons.event_busy_rounded,
                  tooltip: 'Gecikmiş (bitiş tarihi geçmiş) işler',
                  selected: filter == MyWorkFilter.overdue,
                  onPressed: onFilterOverdue,
                ),
                const SizedBox(width: 4),
                FilterIconButton(
                  icon: Icons.filter_alt_outlined,
                  selectedIcon: Icons.filter_alt_rounded,
                  tooltip: 'Yalnızca aktif projedeki işleri göster',
                  selected: onlyActiveProject,
                  onPressed: onOnlyActiveProject,
                ),
                const SizedBox(width: 8),
                FilterIconButton(
                  icon: Icons.view_list_rounded,
                  selectedIcon: Icons.view_list_rounded,
                  tooltip: 'Liste görünümü',
                  selected: viewMode == _ViewMode.list,
                  onPressed: onViewList,
                ),
                const SizedBox(width: 4),
                FilterIconButton(
                  icon: Icons.date_range_rounded,
                  selectedIcon: Icons.date_range_rounded,
                  tooltip: 'Gantt (zaman çizelgesi) görünümü',
                  selected: viewMode == _ViewMode.gantt,
                  onPressed: onViewGantt,
                ),
              ],
            ),
          ),
        if (selectedQuery != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilterIconButton(
                  icon: Icons.view_list_rounded,
                  selectedIcon: Icons.view_list_rounded,
                  tooltip: 'Liste görünümü',
                  selected: viewMode == _ViewMode.list,
                  onPressed: onViewList,
                ),
                const SizedBox(width: 4),
                FilterIconButton(
                  icon: Icons.date_range_rounded,
                  selectedIcon: Icons.date_range_rounded,
                  tooltip: 'Gantt (zaman çizelgesi) görünümü',
                  selected: viewMode == _ViewMode.gantt,
                  onPressed: onViewGantt,
                ),
              ],
            ),
          ),
        if (viewMode == _ViewMode.gantt)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilterIconButton(
                  icon: Icons.event_rounded,
                  selectedIcon: Icons.event_rounded,
                  tooltip: 'Gantt\'ta başlangıç–bitiş tarihine göre çiz',
                  selected: ganttDateSource == GanttDateSource.startDue,
                  onPressed: onGanttStartDue,
                ),
                const SizedBox(width: 4),
                FilterIconButton(
                  icon: Icons.update_rounded,
                  selectedIcon: Icons.update_rounded,
                  tooltip: 'Gantt\'ta güncelleme tarihine göre çiz',
                  selected: ganttDateSource == GanttDateSource.updatedAt,
                  onPressed: onGanttUpdatedAt,
                ),
              ],
            ),
          ),
        if (selectedQuery == null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              filterSortSummary,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
      ],
    );
  }
}
