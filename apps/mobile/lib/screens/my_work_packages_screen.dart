import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/saved_query.dart';
import '../models/work_package.dart';
import '../state/auth_state.dart';
import '../utils/app_logger.dart';
import '../utils/error_messages.dart';
import '../utils/haptic.dart';
import '../widgets/letter_avatar.dart';
import '../widgets/projectflow_logo_button.dart';
import '../widgets/work_package_list_actions.dart';
import '../widgets/work_packages_gantt.dart';
import 'create_work_package_screen.dart';
import 'work_package_detail_screen.dart';

enum MyWorkFilter { all, today, overdue }
enum MyWorkSort { dueDateAsc, dueDateDesc }
enum _ViewMode { list, gantt }

/// Listede kullanılabilecek kolon id'leri (API QueryColumn id ile eşleşir).
const _kColumnIds = ['id', 'subject', 'type', 'status', 'priority', 'dueDate', 'updated_at'];
const _kColumnLabels = {'id': 'ID', 'subject': 'Başlık', 'type': 'Tür', 'status': 'Durum', 'priority': 'Öncelik', 'dueDate': 'Bitiş tarihi', 'updated_at': 'Güncellenme'};

/// Filtre formu: OpenProject work_packages destekli alanlar (API filter name).
const _kFilterFieldIds = ['status', 'type', 'assignee', 'project', 'priority', 'dueDate', 'author', 'subjectOrId', 'createdAt', 'updatedAt', 'responsible'];
const _kFilterFieldLabels = {
  'status': 'Durum', 'type': 'Tür', 'assignee': 'Atanan', 'project': 'Proje', 'priority': 'Öncelik',
  'dueDate': 'Bitiş tarihi', 'author': 'Yazar', 'subjectOrId': 'Başlık/ID', 'createdAt': 'Oluşturulma', 'updatedAt': 'Güncellenme', 'responsible': 'Sorumlu',
};

/// Filtre operatörleri (OpenProject API symbol -> kısa açıklama). Değer gerektirmeyenler: *, !*, o, c, t, w.
const _kFilterOperatorList = [
  ('=', 'eşittir'),
  ('!', 'eşit değil'),
  ('*', 'dolu (değer var)'),
  ('!*', 'boş'),
  ('**', 'içerir (aranan)'),
  ('o', 'açık (durum)'),
  ('c', 'kapalı (durum)'),
  ('t', 'bugün'),
  ('w', 'bu hafta'),
  ('>=', 'büyük eşit'),
  ('<=', 'küçük eşit'),
  ('t+', 'gelecek X gün'),
  ('t-', 'geçmiş X gün'),
  ('=d', 'tarih eşit'),
  ('<>d', 'tarih aralığı'),
];

/// Query görünümü için tek bir liste modeli:
/// - Grup başlık satırları
/// - İş paketi satırları (opsiyonel hiyerarşi derinliği ile)
class _QueryRow {
  final bool isGroupHeader;
  final String? groupLabel;
  final WorkPackage? workPackage;
  final int depth;
  /// Hiyerarşik görünümde: bu satırın çocukları var mı?
  final bool hasChildren;

  const _QueryRow._({
    required this.isGroupHeader,
    this.groupLabel,
    this.workPackage,
    this.depth = 0,
    this.hasChildren = false,
  });

  factory _QueryRow.groupHeader(String label) {
    return _QueryRow._(
      isGroupHeader: true,
      groupLabel: label,
      workPackage: null,
      depth: 0,
      hasChildren: false,
    );
  }

  factory _QueryRow.workPackage(WorkPackage wp, {int depth = 0, bool hasChildren = false}) {
    return _QueryRow._(
      isGroupHeader: false,
      groupLabel: null,
      workPackage: wp,
      depth: depth,
      hasChildren: hasChildren,
    );
  }
}

class MyWorkPackagesScreen extends StatefulWidget {
  /// Dashboard vb. yerlerden görünümle açıldığında kullanılır.
  final SavedQuery? initialQuery;

  const MyWorkPackagesScreen({super.key, this.initialQuery});

  @override
  State<MyWorkPackagesScreen> createState() => _MyWorkPackagesScreenState();
}

/// Varsayılan görünümde bir sayfada yüklenecek kayıt sayısı (P0-F03).
const _kDefaultPageSize = 20;

class _MyWorkPackagesScreenState extends State<MyWorkPackagesScreen> {
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
  int _pageSize = _kDefaultPageSize;

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
    } catch (_) {
      // Görünüm listesi opsiyonel
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
        _error = 'Sunucu yanıt vermedi (zaman aşımı). Bağlantıyı kontrol edip tekrar deneyin veya varsayılan görünüme dönün.';
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
    } catch (_) {
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
      final client = context.read<AuthState>().client;
      if (client == null) return;
      final normalizedFilters = _normalizeFilters(_userFilters);
      final result = await client.getQueryWithResults(
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
    } catch (_) {
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
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Kayıtlı görünüm bulunamadı.', style: TextStyle(fontSize: 12)),
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
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Sırala'),
              ),
              RadioListTile<MyWorkSort>(
                value: MyWorkSort.dueDateAsc,
                groupValue: _sort,
                onChanged: (v) => Navigator.pop(context, v),
                title: const Text('Bitiş tarihi ↑ (en yakın önce)'),
              ),
              RadioListTile<MyWorkSort>(
                value: MyWorkSort.dueDateDesc,
                groupValue: _sort,
                onChanged: (v) => Navigator.pop(context, v),
                title: const Text('Bitiş tarihi ↓ (en geç önce)'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      setState(() => _sort = selected);
    }
  }

  Future<void> _openColumnsSheet() async {
    Set<String> visible = Set<String>.from(_visibleColumnIds)..remove('assignee');

    final result = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final maxH = MediaQuery.of(context).size.height * 0.7;
            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxH),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const ListTile(
                        title: Text('Kolonlar'),
                        subtitle: Text('Listede hangi alanlar görünsün?'),
                      ),
                      ..._kColumnIds.map((id) => SwitchListTile(
                        value: visible.contains(id),
                        title: Text(_kColumnLabels[id] ?? id),
                        onChanged: (v) {
                          setModalState(() {
                            if (v) visible.add(id); else visible.remove(id);
                          });
                        },
                      )),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('İptal'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Uygula'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (result == true && visible.isNotEmpty) {
      setState(() => _visibleColumnIds = visible..remove('assignee'));
    }
  }

  /// Operatör değer gerektiriyor mu? (boş values kabul edenler: *, !*, o, c, t, w)
  static bool _operatorNeedsValues(String op) {
    return !['*', '!*', 'o', 'c', 't', 'w'].contains(op);
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
      if (_operatorNeedsValues(op)) {
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

  /// Filtre formu: kolon/operatör/değer ile OpenProject API filtreleri ekle/kaldır; Uygula ile _userFilters güncellenir ve _load() çağrılır.
  Future<void> _openFilterSheet() async {
    final source = (_selectedQuery != null && !_userFiltersDirty) ? _queryFilters : _userFilters;
    List<Map<String, dynamic>> editing = List<Map<String, dynamic>>.from(
      source.map((f) {
        final entry = f.entries.first;
        final key = entry.key;
        final val = entry.value as Map<String, dynamic>? ?? {};
        final op = val['operator']?.toString() ?? '=';
        final values = val['values'] as List?;
        final valuesList = values != null ? values.map((e) => e.toString()).toList() : <String>[];
        return {'field': key, 'operator': op, 'values': valuesList, 'valuesInput': valuesList.join(', ')};
      }),
    );

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            final maxH = MediaQuery.of(context).size.height * 0.8;
            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxH),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ListTile(
                      title: const Text('Filtreler'),
                      subtitle: Text(
                        'Kolon, operatör ve değer seçin. Birden fazla filtre AND ile birleşir.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        itemCount: editing.length,
                        itemBuilder: (context, i) {
                          final f = editing[i];
                          final field = f['field'] as String? ?? 'status';
                          final op = f['operator'] as String? ?? '=';
                          final values = (f['values'] as List<dynamic>?)?.cast<String>() ?? [];
                          final valuesStr = values.join(', ');
                          final needsVal = _operatorNeedsValues(op);
                          final fieldOptions = <String>[
                            if (!_kFilterFieldIds.contains(field)) field,
                            ..._kFilterFieldIds,
                          ];
                          final operatorOptions = <(String, String)>[
                            if (!_kFilterOperatorList.any((e) => e.$1 == op)) (op, op),
                            ..._kFilterOperatorList,
                          ];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: DropdownButtonFormField<String>(
                                          value: fieldOptions.contains(field) ? field : fieldOptions.first,
                                          isExpanded: true,
                                          iconSize: 18,
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          ),
                                          items: fieldOptions.map((id) {
                                            return DropdownMenuItem(
                                              value: id,
                                              child: Text(
                                                _kFilterFieldLabels[id] ?? id,
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                                softWrap: false,
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (v) {
                                            if (v != null) setModalState(() => f['field'] = v);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          value: operatorOptions.any((e) => e.$1 == op) ? op : operatorOptions.first.$1,
                                          isExpanded: true,
                                          iconSize: 18,
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          ),
                                          items: operatorOptions.map((e) {
                                            return DropdownMenuItem(
                                              value: e.$1,
                                              child: Text(
                                                e.$2,
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                                softWrap: false,
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (v) {
                                            if (v != null) setModalState(() => f['operator'] = v);
                                          },
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close_rounded, size: 20),
                                        onPressed: () => setModalState(() => editing.removeAt(i)),
                                      ),
                                    ],
                                  ),
                                  if (needsVal) ...[
                                    const SizedBox(height: 4),
                                    TextField(
                                      controller: TextEditingController(text: f['valuesInput'] ?? valuesStr),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        hintText: 'Değerler (virgülle ayırın; assignee için "me")',
                                      ),
                                      onChanged: (text) {
                                        setModalState(() {
                                          f['valuesInput'] = text;
                                          f['values'] = text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                                        });
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              setModalState(() {
                                editing.add({'field': 'status', 'operator': '=', 'values': <String>[], 'valuesInput': ''});
                              });
                            },
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Filtre ekle'),
                          ),
                          const SizedBox(height: 8),
                          if (editing.isNotEmpty)
                            OutlinedButton(
                              onPressed: () => setModalState(() => editing.clear()),
                              child: const Text('Tümünü temizle'),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('İptal'),
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Uygula'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != true) return;

    final newFilters = <Map<String, dynamic>>[];
    for (final f in editing) {
      final field = f['field'] as String?;
      final op = f['operator'] as String? ?? '=';
      List<String> values = (f['values'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? <String>[];
      final input = f['valuesInput']?.toString() ?? '';
      if (input.trim().isNotEmpty) {
        values = input.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
      if (field == null || field.isEmpty) continue;
      newFilters.add({
        field: {'operator': op, 'values': values},
      });
    }
    setState(() {
      _userFilters = newFilters;
      _userFiltersDirty = true;
    });
    _load();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final d = date.toLocal();
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

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

  Widget _buildNotificationAction(AuthState auth) {
    final count = auth.unreadNotificationCount;
    final button = Tooltip(
      message: 'Bildirimleri aç',
      waitDuration: const Duration(milliseconds: 500),
      showDuration: const Duration(seconds: 2),
      child: IconButton(
        onPressed: () {
          Navigator.of(context).pushNamed('/notifications').then((_) {
            auth.refreshUnreadNotificationCount();
          });
        },
        icon: const Icon(Icons.notifications_outlined, size: 22),
        tooltip: 'Bildirimleri aç',
      ),
    );
    if (count <= 0) return button;
    return Badge(
      offset: const Offset(-6, 4),
      label: Text(count > 99 ? '99+' : '$count'),
      child: button,
    );
  }

  String _cellText(WorkPackage wp, String columnId) {
    switch (columnId) {
      case 'id': return wp.id;
      case 'subject': return wp.subject;
      case 'type': return wp.typeName ?? '';
      case 'status': return wp.statusName;
      case 'priority': return wp.priorityName ?? '';
      case 'assignee': return wp.assigneeName ?? '';
      case 'dueDate': return wp.dueDate != null ? _formatDate(wp.dueDate) : '';
      case 'updated_at': return wp.updatedAt != null ? _formatDate(wp.updatedAt) : '';
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
    return (theme.colorScheme.surfaceVariant, theme.colorScheme.onSurfaceVariant, Icons.label_rounded);
  }

  /// Query modunda (seçili görünüm) kullanılacak satır modeli: grup başlığı veya iş paketi + hiyerarşik seviye.
  List<_QueryRow> _buildQueryRows() {
    if (_selectedQuery == null) {
      return _visibleItems.map((wp) => _QueryRow.workPackage(wp)).toList();
    }
    final q = _selectedQuery!;
    if (q.groupBy != null && q.groupBy!.isNotEmpty) {
      return _buildGroupedRows(q.groupBy!);
    }
    if (q.showHierarchies) {
      return _buildHierarchyRows();
    }
    return _items.map((wp) => _QueryRow.workPackage(wp)).toList();
  }

  List<_QueryRow> _buildHierarchyRows() {
    final byId = <String, WorkPackage>{for (final wp in _items) wp.id: wp};
    final childrenOf = <String, List<WorkPackage>>{};
    for (final wp in _items) {
      final parentId = wp.parentId;
      if (parentId != null && parentId.isNotEmpty && byId.containsKey(parentId)) {
        childrenOf.putIfAbsent(parentId, () => []).add(wp);
      }
    }
    final visited = <String>{};
    final rows = <_QueryRow>[];

    void visit(WorkPackage wp, int depth) {
      if (visited.contains(wp.id)) return;
      visited.add(wp.id);
      final kids = childrenOf[wp.id] ?? const [];
      final hasChildren = kids.isNotEmpty;
      rows.add(_QueryRow.workPackage(wp, depth: depth, hasChildren: hasChildren));
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

  List<_QueryRow> _buildGroupedRows(String groupBy) {
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

    final rows = <_QueryRow>[];
    final keys = groups.keys.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    for (final key in keys) {
      rows.add(_QueryRow.groupHeader(key));
      final groupKey = '$groupBy::$key';
      if (_collapsedGroups.contains(groupKey)) continue;
      for (final wp in groups[key]!) {
        rows.add(_QueryRow.workPackage(wp));
      }
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final projectName = auth.activeProject?.name ?? 'Benim işlerim';
    final items = _visibleItems;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          projectName,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        actions: [
          Tooltip(
            message: 'Yeni iş paketi oluştur',
            waitDuration: const Duration(milliseconds: 500),
            showDuration: const Duration(seconds: 2),
            child: IconButton(
              onPressed: () {
                mediumImpact();
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (_) => const CreateWorkPackageScreen(),
                      ),
                    )
                    .then((_) => _load());
              },
              icon: const Icon(Icons.add_rounded, size: 24),
              tooltip: 'Yeni iş paketi oluştur',
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
          _buildNotificationAction(auth),
        ],
      ),
      floatingActionButton: Tooltip(
        message: 'Listeyi yenile',
        waitDuration: const Duration(milliseconds: 500),
        showDuration: const Duration(seconds: 2),
        child: FloatingActionButton.small(
          onPressed: () {
            mediumImpact();
            _load();
          },
          child: const Icon(Icons.refresh_rounded, size: 20),
        ),
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
                        if (_selectedQuery != null) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedQuery = null;
                                _error = null;
                              });
                              _load();
                            },
                            child: const Text('Varsayılan görünüme dön'),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : items.isEmpty
                  ? const Center(child: Text('Üzerine atanmış açık iş bulunamadı.'))
                  : Stack(
                      children: [
                        Column(
                          children: [
                        if (_selectedQuery == null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FilterIconButton(
                                  icon: Icons.filter_list_rounded,
                                  selectedIcon: Icons.filter_list_rounded,
                                  tooltip: 'Tüm açık işlerimi göster',
                                  selected: _filter == MyWorkFilter.all,
                                  onPressed: () => _changeFilter(MyWorkFilter.all),
                                ),
                                const SizedBox(width: 4),
                                FilterIconButton(
                                  icon: Icons.today_outlined,
                                  selectedIcon: Icons.today_rounded,
                                  tooltip: 'Bugün bitiş tarihli işler',
                                  selected: _filter == MyWorkFilter.today,
                                  onPressed: () => _changeFilter(MyWorkFilter.today),
                                ),
                                const SizedBox(width: 4),
                                FilterIconButton(
                                  icon: Icons.event_busy_outlined,
                                  selectedIcon: Icons.event_busy_rounded,
                                  tooltip: 'Gecikmiş (bitiş tarihi geçmiş) işler',
                                  selected: _filter == MyWorkFilter.overdue,
                                  onPressed: () => _changeFilter(MyWorkFilter.overdue),
                                ),
                                const SizedBox(width: 4),
                                FilterIconButton(
                                  icon: Icons.filter_alt_outlined,
                                  selectedIcon: Icons.filter_alt_rounded,
                                  tooltip: 'Yalnızca aktif projedeki işleri göster',
                                  selected: _onlyActiveProject,
                                  onPressed: () {
                                    setState(() => _onlyActiveProject = !_onlyActiveProject);
                                    _load();
                                    _loadQueries();
                                  },
                                ),
                                const SizedBox(width: 8),
                                FilterIconButton(
                                  icon: Icons.view_list_rounded,
                                  selectedIcon: Icons.view_list_rounded,
                                  tooltip: 'Liste görünümü',
                                  selected: _viewMode == _ViewMode.list,
                                  onPressed: () {
                                    mediumImpact();
                                    setState(() => _viewMode = _ViewMode.list);
                                  },
                                ),
                                const SizedBox(width: 4),
                                FilterIconButton(
                                  icon: Icons.date_range_rounded,
                                  selectedIcon: Icons.date_range_rounded,
                                  tooltip: 'Gantt (zaman çizelgesi) görünümü',
                                  selected: _viewMode == _ViewMode.gantt,
                                  onPressed: () {
                                    mediumImpact();
                                    setState(() => _viewMode = _ViewMode.gantt);
                                  },
                                ),
                              ],
                            ),
                          ),
                        if (_selectedQuery != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FilterIconButton(
                                  icon: Icons.view_list_rounded,
                                  selectedIcon: Icons.view_list_rounded,
                                  tooltip: 'Liste görünümü',
                                  selected: _viewMode == _ViewMode.list,
                                  onPressed: () {
                                    mediumImpact();
                                    setState(() => _viewMode = _ViewMode.list);
                                  },
                                ),
                                const SizedBox(width: 4),
                                FilterIconButton(
                                  icon: Icons.date_range_rounded,
                                  selectedIcon: Icons.date_range_rounded,
                                  tooltip: 'Gantt (zaman çizelgesi) görünümü',
                                  selected: _viewMode == _ViewMode.gantt,
                                  onPressed: () {
                                    mediumImpact();
                                    setState(() => _viewMode = _ViewMode.gantt);
                                  },
                                ),
                              ],
                            ),
                          ),
                        if (_viewMode == _ViewMode.gantt)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FilterIconButton(
                                  icon: Icons.event_rounded,
                                  selectedIcon: Icons.event_rounded,
                                  tooltip: 'Gantt\'ta başlangıç–bitiş tarihine göre çiz',
                                  selected: _ganttDateSource == GanttDateSource.startDue,
                                  onPressed: () {
                                    mediumImpact();
                                    setState(() => _ganttDateSource = GanttDateSource.startDue);
                                  },
                                ),
                                const SizedBox(width: 4),
                                FilterIconButton(
                                  icon: Icons.update_rounded,
                                  selectedIcon: Icons.update_rounded,
                                  tooltip: 'Gantt\'ta güncelleme tarihine göre çiz',
                                  selected: _ganttDateSource == GanttDateSource.updatedAt,
                                  onPressed: () {
                                    mediumImpact();
                                    setState(() => _ganttDateSource = GanttDateSource.updatedAt);
                                  },
                                ),
                              ],
                            ),
                          ),
                        if (_selectedQuery == null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: Text(
                              _filterSortSummary,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
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
                                    itemCount: _selectedQuery != null
                                        ? _buildQueryRows().length + (_showLoadMoreQuery ? 1 : 0)
                                        : items.length + (_showLoadMore ? 1 : 0),
                                    separatorBuilder: (_, __) => const Divider(height: 1),
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
                                                child: CircularProgressIndicator(strokeWidth: 2),
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
                                                  child: CircularProgressIndicator(strokeWidth: 2),
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
                                      color: Theme.of(context).colorScheme.surfaceVariant,
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
                                    } else if (id == 'assignee') {
                                      meta.add(Text(
                                        wp.assigneeName ?? 'Atanmamış',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ));
                                    } else {
                                      final label = _kColumnLabels[id] ?? id;
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
                                          color: Theme.of(context).colorScheme.surfaceVariant,
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
                                      );
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
                                } else if (id == 'assignee') {
                                  meta.add(Text(
                                    wp.assigneeName ?? 'Atanmamış',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ));
                                } else {
                                  final label = _kColumnLabels[id] ?? id;
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
                                      color: Theme.of(context).colorScheme.surfaceVariant,
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
                                  );
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
                          ),
                        ),
                      ],
                    ),
    );
  }
}
