import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/openproject_client.dart';
import '../models/time_entry.dart';
import '../models/work_package.dart';
import '../state/auth_state.dart';
import '../state/time_tracking_prefs.dart';
import '../utils/app_logger.dart';
import '../utils/error_messages.dart';
import '../utils/haptic.dart';
import '../widgets/time_tracking_data_table.dart';
import '../widgets/time_tracking_entry_detail_sheet.dart';
import 'work_package_detail_screen.dart';

/// Zaman takibi sayfası: varsayılan/özel kolonlar, gruplama, ekip modu, detay + işe git.
class TimeTrackingScreen extends StatefulWidget {
  const TimeTrackingScreen({super.key});

  @override
  State<TimeTrackingScreen> createState() => _TimeTrackingScreenState();
}

class _TimeTrackingScreenState extends State<TimeTrackingScreen> {
  bool _loading = true;
  String? _error;
  List<TimeEntry> _entries = const [];
  List<String> _columns = List.from(kDefaultTimeTrackingColumns);
  TimeTrackingGroupBy _groupBy = TimeTrackingGroupBy.day;
  bool _showTeam = false;
  String? _selectedUserId;
  List<Map<String, String>> _projectMembers = const [];

  static DateTime get _now => DateTime.now();
  static DateTime get _today => DateTime(_now.year, _now.month, _now.day);

  OpenProjectClient? _client(BuildContext context) =>
      context.read<AuthState>().client;

  /// Son 90 gün için kayıtları yükle (kendi veya ekip modunda seçili kullanıcı).
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = _client(context);
      if (client == null) throw Exception('Oturum bulunamadı.');
      final end = _today.add(const Duration(days: 1));
      final start = _today.subtract(const Duration(days: 90));
      final userId = _showTeam && _selectedUserId != null && _selectedUserId!.isNotEmpty
          ? _selectedUserId
          : null;
      _entries = await client.getMyTimeEntries(from: start, to: end, userId: userId);
    } catch (e, st) {
      AppLogger.logError('Zaman takibi yüklenirken hata', error: e);
      if (kDebugMode && st != null) {
        debugPrintStack(stackTrace: st);
      }
      _error = ErrorMessages.userFriendly(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  double _totalToday() {
    return _entries
        .where((e) =>
            e.spentOn.year == _today.year &&
            e.spentOn.month == _today.month &&
            e.spentOn.day == _today.day)
        .fold(0.0, (sum, e) => sum + e.hours);
  }

  double _totalThisWeek() {
    final monday = _today.subtract(Duration(days: _today.weekday - 1));
    final nextMonday = monday.add(const Duration(days: 7));
    return _entries.where((e) {
      final d = DateTime(e.spentOn.year, e.spentOn.month, e.spentOn.day);
      return !d.isBefore(monday) && d.isBefore(nextMonday);
    }).fold(0.0, (sum, e) => sum + e.hours);
  }

  double _totalThisMonth() {
    return _entries
        .where((e) =>
            e.spentOn.year == _today.year && e.spentOn.month == _today.month)
        .fold(0.0, (sum, e) => sum + e.hours);
  }

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

  /// Haftanın pazartesi günü (local).
  DateTime _weekStart(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  void _openAddTimeEntry() async {
    final auth = context.read<AuthState>();
    final client = _client(context);
    final projectId = auth.activeProject?.id;
    if (client == null || projectId == null || projectId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Aktif proje yok. Önce bir proje seçin.')),
        );
      }
      return;
    }
    mediumImpact();
    List<WorkPackage> workPackages = [];
    try {
      final result = await client.getMyOpenWorkPackages(
        projectId: projectId,
        pageSize: 100,
        offset: 1,
      );
      workPackages = result.workPackages;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İş listesi yüklenemedi.')),
        );
      }
      return;
    }
    if (!mounted) return;
    if (workPackages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Bu projede açık iş yok. Önce iş oluşturun.')),
      );
      return;
    }
    final selected = await showModalBottomSheet<WorkPackage>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Zaman eklemek için iş seçin',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: workPackages.length,
                  itemBuilder: (context, index) {
                    final wp = workPackages[index];
                    return ListTile(
                      title: Text('#${wp.id} · ${wp.subject}'),
                      subtitle: Text(wp.statusName),
                      onTap: () {
                        lightImpact();
                        Navigator.of(context).pop(wp);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected == null || !mounted) return;
    await _showTimeEntryForm(selected);
  }

  Future<void> _showTimeEntryForm(WorkPackage workPackage) async {
    final hoursController = TextEditingController();
    final commentController = TextEditingController();
    DateTime pickedDate = DateTime.now();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '#${workPackage.id} · ${workPackage.subject}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: pickedDate,
                            firstDate:
                                DateTime(pickedDate.year - 1, pickedDate.month),
                            lastDate:
                                DateTime(pickedDate.year + 1, pickedDate.month),
                          );
                          if (d != null) {
                            setModalState(() => pickedDate = d);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Tarih',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(_formatDate(pickedDate)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: hoursController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Saat',
                          hintText: '1.0',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: commentController,
                        minLines: 1,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Açıklama (isteğe bağlı)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('İptal'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () async {
                              final hoursText = hoursController.text
                                  .trim()
                                  .replaceAll(',', '.');
                              final h = double.tryParse(hoursText);
                              if (h == null || h <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Geçerli bir saat girin (örn. 0.5, 1, 1.5)'),
                                  ),
                                );
                                return;
                              }
                              try {
                                final client = _client(context);
                                if (client == null) return;
                                await client.createTimeEntry(
                                  workPackageId: workPackage.id,
                                  hours: h,
                                  spentOn: pickedDate,
                                  comment: commentController.text.trim(),
                                );
                                if (context.mounted) {
                                  Navigator.of(context).pop(true);
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            ErrorMessages.userFriendly(e))),
                                  );
                                }
                              }
                            },
                            child: const Text('Kaydet'),
                          ),
                        ],
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
    if (saved == true && mounted) await _load();
  }

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _load();
  }

  Future<void> _loadPrefs() async {
    final columns = await TimeTrackingPrefs.getColumns();
    final groupBy = await TimeTrackingPrefs.getGroupBy();
    final showTeam = await TimeTrackingPrefs.getShowTeam();
    if (!mounted) return;
    setState(() {
      _columns = columns;
      _groupBy = groupBy;
      _showTeam = showTeam;
    });
    if (showTeam) _loadProjectMembers();
  }

  Future<void> _loadProjectMembers() async {
    final auth = context.read<AuthState>();
    final client = _client(context);
    final projectId = auth.activeProject?.id;
    if (client == null || projectId == null) return;
    try {
      final members = await client.getProjectMembers(projectId);
      final me = auth.client;
      String? myId;
      if (me != null) {
        try {
          final data = await me.getMe();
          myId = data['id']?.toString();
        } catch (_) {}
      }
      final list = <Map<String, String>>[];
      if (myId != null) {
        list.add({
          'id': myId,
          'name': '${auth.userDisplayName ?? auth.userLogin ?? 'Ben'} (ben)',
        });
      }
      for (final m in members) {
        if (m['id'] != myId) list.add(m);
      }
      if (!mounted) return;
      setState(() {
        _projectMembers = list;
        if (_selectedUserId == null && list.isNotEmpty) _selectedUserId = list.first['id'];
      });
    } catch (_) {
      if (mounted) setState(() => _projectMembers = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zaman takibi'),
        actions: [
          IconButton(
            onPressed: () => _openColumnSelector(context),
            icon: const Icon(Icons.view_column),
            tooltip: 'Kolonlar',
          ),
          IconButton(
            onPressed: () async {
              lightImpact();
              await _load();
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
          ),
        ],
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
                        Text(_error!, textAlign: TextAlign.center),
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
                        Row(
                          children: [
                            Expanded(
                              child: _SummaryCard(
                                title: 'Bugün',
                                hours: _totalToday(),
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _SummaryCard(
                                title: 'Bu hafta',
                                hours: _totalThisWeek(),
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _SummaryCard(
                                title: 'Bu ay',
                                hours: _totalThisMonth(),
                                color: theme.colorScheme.tertiary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text('Gruplama', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<TimeTrackingGroupBy>(
                          value: _groupBy,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: TimeTrackingGroupBy.values
                              .map((g) => DropdownMenuItem(
                                    value: g,
                                    child: Text(g.label),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            lightImpact();
                            setState(() => _groupBy = v);
                            TimeTrackingPrefs.setGroupBy(v);
                          },
                        ),
                        if (auth.activeProject != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Ekip zamanları',
                                  style: theme.textTheme.titleSmall,
                                ),
                              ),
                              Switch(
                                value: _showTeam,
                                onChanged: (v) async {
                                  lightImpact();
                                  setState(() => _showTeam = v);
                                  TimeTrackingPrefs.setShowTeam(v);
                                  if (v) {
                                    await _loadProjectMembers();
                                    if (mounted) _load();
                                  } else {
                                    _load();
                                  }
                                },
                              ),
                            ],
                          ),
                          if (_showTeam) ...[
                            if (_projectMembers.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Proje üyeleri yükleniyor…',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              )
                            else ...[
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _selectedUserId,
                                decoration: const InputDecoration(
                                  labelText: 'Kullanıcı',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                items: _projectMembers
                                    .map((m) => DropdownMenuItem(
                                          value: m['id'],
                                          child: Text(
                                            m['name'] ?? m['id'] ?? '',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ))
                                    .toList(),
                                onChanged: (v) {
                                  lightImpact();
                                  setState(() => _selectedUserId = v);
                                  _load();
                                },
                              ),
                            ],
                          ],
                        ],
                        const SizedBox(height: 16),
                        TimeTrackingDataTable(
                          entries: _entries,
                          columnIds: _columns,
                          groupBy: _groupBy,
                          onEntryTap: (e) => showTimeEntryDetailSheet(
                            context: context,
                            entry: e,
                            onOpenWorkPackage: _openWorkPackageFromTimeEntry,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddTimeEntry,
        tooltip: 'Zaman kaydı ekle',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openWorkPackageFromTimeEntry(WorkPackage wp) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkPackageDetailScreen(workPackage: wp),
      ),
    );
  }

  void _openColumnSelector(BuildContext context) {
    lightImpact();
    final theme = Theme.of(context);
    var selected = List<String>.from(_columns);
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Kolonları seçin',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...kAllTimeTrackingColumns.map((colId) {
                    final label = colId == 'date'
                        ? 'Tarih'
                        : colId == 'hours'
                            ? 'Saat'
                            : colId == 'work_package'
                                ? 'İş'
                                : colId == 'comment'
                                    ? 'Açıklama'
                                    : colId == 'activity'
                                        ? 'Aktivite'
                                        : 'Kullanıcı';
                    final isSelected = selected.contains(colId);
                    return CheckboxListTile(
                      value: isSelected,
                      title: Text(label),
                      onChanged: (v) {
                        setModalState(() {
                          if (v == true) {
                            if (!selected.contains(colId)) selected.add(colId);
                          } else {
                            selected.remove(colId);
                          }
                          if (selected.isEmpty) selected = List.from(kDefaultTimeTrackingColumns);
                        });
                      },
                    );
                  }),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('İptal'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          if (selected.isEmpty) selected = List.from(kDefaultTimeTrackingColumns);
                          setState(() => _columns = selected);
                          TimeTrackingPrefs.setColumns(selected);
                          Navigator.pop(ctx);
                        },
                        child: const Text('Uygula'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double hours;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.hours,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${hours.toStringAsFixed(1)} s',
              style: theme.textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

