import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../mixins/client_context_mixin.dart';
import '../models/time_entry.dart';
import '../models/time_entry_activity.dart';
import '../state/auth_state.dart';
import '../state/time_tracking_prefs.dart';
import '../utils/app_logger.dart';
import '../utils/error_messages.dart';
import '../utils/haptic.dart';
import '../utils/date_formatters.dart';
import '../utils/time_entry_helpers.dart';
import 'async_content.dart';
import 'time_tracking_data_table.dart';

/// İş paketi detay ekranında zaman kayıtları sekmesi.
/// [WorkPackageTimeEntriesTabState.refresh] üst ekran veya RouteAware didPopNext ile çağrılabilir.
class WorkPackageTimeEntriesTab extends StatefulWidget {
  final String workPackageId;

  const WorkPackageTimeEntriesTab({super.key, required this.workPackageId});

  @override
  State<WorkPackageTimeEntriesTab> createState() => WorkPackageTimeEntriesTabState();
}

class WorkPackageTimeEntriesTabState extends State<WorkPackageTimeEntriesTab>
    with ClientContextMixin<WorkPackageTimeEntriesTab> {
  /// Üst ekran (RouteAware didPopNext) veya dışarıdan tetiklenen yenileme.
  void refresh() => _load();
  bool _loading = true;
  String? _error;
  List<TimeEntry> _items = const [];
  List<String> _columns = List.from(kDefaultTimeTrackingColumns);
  List<TimeEntryActivity> _activities = const [];
  String? _selectedActivityId;

  final TextEditingController _hoursController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  DateTime _date = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);

  @override
  void initState() {
    super.initState();
    _load();
    _loadActivities();
    _updateSuggestedTimes();
  }

  Future<void> _updateSuggestedTimes() async {
    final c = client;
    if (c == null) return;
    final workStart = await TimeTrackingPrefs.getWorkStartTimeOfDay();
    final dayStart = DateTime(_date.year, _date.month, _date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    List<TimeEntry> dayEntries = [];
    try {
      final me = await c.getMe();
      final userId = me['id'];
      dayEntries = await c.getMyTimeEntries(from: dayStart, to: dayEnd, userId: userId);
    } catch (e) {
      if (kDebugMode) AppLogger.logError('Zaman kayıtları (gün) yüklenirken hata', error: e);
    }
    final totalHours = dayEntries.fold<double>(0, (s, e) => s + e.hours);
    final suggestedStart = addHoursToTimeOfDay(workStart, totalHours);
    final suggestedEnd = addHoursToTimeOfDay(suggestedStart, 1.0);
    if (!mounted) return;
    setState(() {
      _startTime = suggestedStart;
      _endTime = suggestedEnd;
      _hoursController.text = timeOfDayDiffHours(_startTime, _endTime).toStringAsFixed(2);
    });
  }

  Future<void> _loadActivities() async {
    final c = client;
    if (c == null) return;
    try {
      final list = await c.getTimeEntryActivities();
      if (!mounted) return;
      final defaultList = list.where((a) => a.isDefault).toList();
      setState(() {
        _activities = list;
        _selectedActivityId = list.isEmpty
            ? null
            : (defaultList.isNotEmpty ? defaultList.first.id : list.first.id);
      });
    } catch (e) {
      if (kDebugMode) AppLogger.logError('Zaman girişi aktiviteleri yüklenirken hata', error: e);
    }
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final c = client;
      if (c == null) throw Exception('Oturum bulunamadı.');
      _items = await c.getWorkPackageTimeEntries(widget.workPackageId);
      final order = await TimeTrackingPrefs.getSortOrder();
      final sortBy = await TimeTrackingPrefs.getSortBy();
      _columns = await TimeTrackingPrefs.getColumns();
      TimeTrackingPrefs.sortTimeEntries(_items, order, sortBy);
    } catch (e) {
      _error = ErrorMessages.userFriendly(e);
      AppLogger.logError('Zaman kayıtları yüklenirken hata oluştu', error: e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(_date.year - 1),
      lastDate: DateTime(_date.year + 1),
    );
    if (picked != null) {
      setState(() => _date = picked);
      await _updateSuggestedTimes();
    }
  }

  Future<void> _save() async {
    final hoursText = _hoursController.text.trim().replaceAll(',', '.');
    final h = double.tryParse(hoursText);
    if (h == null || h <= 0) {
      setState(() => _error = 'Lütfen geçerli bir saat değeri girin (örn. 0.5, 1, 1.5).');
      return;
    }
    setState(() => _error = null);
    try {
      final c = client;
      if (c == null) throw Exception('Oturum bulunamadı.');
      await c.createTimeEntry(
        workPackageId: widget.workPackageId,
        hours: h,
        spentOn: _date,
        comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
        activityId: _selectedActivityId,
      );
      _hoursController.clear();
      _commentController.clear();
      await _updateSuggestedTimes();
      await _load();
    } catch (e) {
      setState(() => _error = ErrorMessages.userFriendly(e));
      AppLogger.logError('Zaman kaydı oluşturulurken hata oluştu', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Zaman kaydı ekle',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Tarih',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(DateFormatters.formatDate(_date)),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: _startTime,
                        );
                        if (t != null) {
                          setState(() {
                            _startTime = t;
                            final h = double.tryParse(_hoursController.text.trim().replaceAll(',', '.')) ?? 1.0;
                            _endTime = addHoursToTimeOfDay(_startTime, h);
                            _hoursController.text = timeOfDayDiffHours(_startTime, _endTime).toStringAsFixed(2);
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Başlangıç',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(formatTimeOfDay(_startTime)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: _endTime,
                        );
                        if (t != null) {
                          setState(() {
                            _endTime = t;
                            _hoursController.text = timeOfDayDiffHours(_startTime, _endTime).toStringAsFixed(2);
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Bitiş',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(formatTimeOfDay(_endTime)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _hoursController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Süre (saat)',
                  hintText: '1.0',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (_) {
                  setState(() {
                    final h = double.tryParse(_hoursController.text.trim().replaceAll(',', '.'));
                    if (h != null && h > 0) {
                      _endTime = addHoursToTimeOfDay(_startTime, h);
                    }
                  });
                },
              ),
              if (_activities.isNotEmpty) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedActivityId,
                  decoration: InputDecoration(
                    labelText: 'Kategori (Aktivite)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _activities
                      .map((a) => DropdownMenuItem(
                            value: a.id,
                            child: Text(a.name),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedActivityId = v),
                ),
              ],
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Yorum (isteğe bağlı)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  alignLabelWithHint: true,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Semantics(
                  label: 'Yorumu kaydet',
                  button: true,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check),
                    label: const Text('Kaydet'),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: AsyncContent(
            loading: _loading,
            error: _error,
            onRetry: _load,
            showEmpty: _items.isEmpty,
            empty: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Bu iş için kayıtlı zaman yok.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
              child: Builder(
                builder: (context) {
                  final auth = context.watch<AuthState>();
                  return TimeTrackingDataTable(
                    entries: _items,
                    columnIds: _columns,
                    groupBy: TimeTrackingGroupBy.none,
                    instanceApiBaseUrl: auth.instanceApiBaseUrl,
                    authHeadersForAvatars: auth.authHeadersForInstanceImages,
                    onEntryTap: (e) {
                      lightImpact();
                      showTimeEntryDetailSheet(
                        context: context,
                        entry: e,
                        onOpenWorkPackage: null,
                        onDeleted: _load,
                        onEditRequested: null,
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
