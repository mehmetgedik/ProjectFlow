import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/openproject_client.dart';
import '../mixins/client_context_mixin.dart';
import '../mixins/loading_error_mixin.dart';
import '../models/time_entry.dart';
import '../models/work_package.dart';
import '../app_navigation.dart';
import '../state/auth_state.dart';
import '../state/pro_state.dart';
import '../state/time_tracking_prefs.dart';
import '../utils/app_logger.dart';
import '../utils/haptic.dart';
import '../utils/snackbar_helpers.dart';
import '../constants/app_strings.dart';
import '../utils/date_formatters.dart';
import '../utils/time_entry_helpers.dart';
import '../models/time_entry_activity.dart';
import '../widgets/async_content.dart';
import '../widgets/pro_gate.dart';
import '../widgets/time_tracking_data_table.dart';
import '../widgets/time_entries_gantt.dart';
import '../widgets/work_package_list_actions.dart';
import '../widgets/time_tracking/add_time_entry_sheet.dart';
import '../widgets/time_tracking/team_selector.dart';
import 'work_package_detail_screen.dart';

enum _TimeViewMode { table, gantt }

/// Zaman takibi sayfası: varsayılan/özel kolonlar, gruplama, ekip modu, detay + işe git.
/// [initialWorkPackageForTime] verilirse açılışta bu iş için zaman kaydı formu açılır (iş listesi uzun basma).
class TimeTrackingScreen extends StatefulWidget {
  final WorkPackage? initialWorkPackageForTime;

  const TimeTrackingScreen({super.key, this.initialWorkPackageForTime});

  @override
  State<TimeTrackingScreen> createState() => _TimeTrackingScreenState();
}

class _TimeTrackingScreenState extends State<TimeTrackingScreen>
    with ClientContextMixin<TimeTrackingScreen>, LoadingErrorMixin<TimeTrackingScreen> {
  List<TimeEntry> _entries = const [];
  List<String> _columns = List.from(kDefaultTimeTrackingColumns);
  TimeTrackingGroupBy _groupBy = TimeTrackingGroupBy.day;
  TimeTrackingSortOrder _sortOrder = TimeTrackingSortOrder.newestFirst;
  TimeTrackingSortBy _sortBy = TimeTrackingSortBy.spentOn;
  bool _showTeam = false;
  String? _selectedUserId;
  List<Map<String, String>> _projectMembers = const [];
  /// Başkasının zaman kayıtlarını görme yetkisi (null = henüz kontrol edilmedi).
  bool? _canViewTeamTime;
  _TimeViewMode _viewMode = _TimeViewMode.table;

  static DateTime get _now => DateTime.now();
  static DateTime get _today => DateTime(_now.year, _now.month, _now.day);

  /// Son 90 gün için kayıtları yükle (kendi veya ekip modunda seçili kullanıcı).
  Future<void> _load() async {
    await runLoad(() async {
      final c = client;
      if (c == null) throw Exception('Oturum bulunamadı.');
      final end = _today.add(const Duration(days: 1));
      final start = _today.subtract(const Duration(days: 90));
      // Personel filtresi: sadece zaman kaydını GİREN kişiye göre (user_id = kaydı oluşturan, iş atanı değil).
      // Ekip kapalıyken benim girdiğim kayıtlar; ekip açıkken seçilen kişinin girdiği kayıtlar.
      String? filterByLoggedByUserId;
      if (_showTeam && _selectedUserId != null && _selectedUserId!.isNotEmpty) {
        filterByLoggedByUserId = _selectedUserId;
      } else {
        final me = await c.getMe();
        filterByLoggedByUserId = me['id'];
      }
      _entries = await c.getMyTimeEntries(from: start, to: end, userId: filterByLoggedByUserId);
      final order = await TimeTrackingPrefs.getSortOrder();
      final sortBy = await TimeTrackingPrefs.getSortBy();
      TimeTrackingPrefs.sortTimeEntries(_entries, order, sortBy);
    }, onError: (e) {
      AppLogger.logError('Zaman takibi yüklenirken hata', error: e);
      if (kDebugMode) debugPrintStack();
    });
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

  void _openAddTimeEntry() async {
    final auth = context.read<AuthState>();
    final c = client;
    final projectId = auth.activeProject?.id;
    if (c == null || projectId == null || projectId.isEmpty) {
      if (mounted) {
        showErrorSnackBar(context, 'Aktif proje yok. Önce bir proje seçin.');
      }
      return;
    }
    mediumImpact();
    List<WorkPackage> workPackages = [];
    try {
      final result = await c.getMyOpenWorkPackages(
        projectId: projectId,
        pageSize: 100,
        offset: 1,
      );
      workPackages = result.workPackages;
    } catch (e) {
      if (kDebugMode) AppLogger.logError('İş listesi yüklenirken hata', error: e);
      if (mounted) {
        showErrorSnackBar(context, AppStrings.errorWorkListLoadFailed);
      }
      return;
    }
    if (!mounted) return;
    if (workPackages.isEmpty) {
      showErrorSnackBar(context, AppStrings.errorNoOpenWorkInProject);
      return;
    }
    final selected = await AddTimeEntrySheet.show(context, workPackages);
    if (selected == null || !mounted) return;
    await _showTimeEntryForm(selected);
  }

  /// Seçilen gün için önerilen başlangıç saati: mesai başlangıcı veya o günkü (kendi) kayıtların toplamından sonra.
  Future<TimeOfDay> _suggestedStartForDate(OpenProjectClient client, DateTime date) async {
    final workStart = await TimeTrackingPrefs.getWorkStartTimeOfDay();
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    List<TimeEntry> dayEntries = [];
    try {
      final me = await client.getMe();
      final userId = me['id'];
      dayEntries = await client.getMyTimeEntries(from: dayStart, to: dayEnd, userId: userId);
    } catch (e) {
      if (kDebugMode) AppLogger.logError('Zaman kayıtları (gün) yüklenirken hata', error: e);
    }
    final totalHours = dayEntries.fold<double>(0, (s, e) => s + e.hours);
    return addHoursToTimeOfDay(workStart, totalHours);
  }

  Future<void> _showTimeEntryForm(WorkPackage workPackage) async {
    final c = client;
    if (c == null) return;
    List<TimeEntryActivity> activities = [];
    try {
      activities = await c.getTimeEntryActivities();
    } catch (e) {
      if (kDebugMode) AppLogger.logError('Zaman girişi aktiviteleri yüklenirken hata', error: e);
    }
    final defaultActivities = activities.where((a) => a.isDefault).toList();
    String? selectedActivityId = activities.isEmpty
        ? null
        : (defaultActivities.isNotEmpty ? defaultActivities.first.id : activities.first.id);

    DateTime pickedDate = DateTime.now();
    TimeOfDay workStartTimeOfDay = await TimeTrackingPrefs.getWorkStartTimeOfDay();
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 10, minute: 0);
    try {
      startTime = await _suggestedStartForDate(c, pickedDate);
      endTime = addHoursToTimeOfDay(startTime, 1.0);
    } catch (e) {
      if (kDebugMode) AppLogger.logError('Önerilen başlangıç saati alınamadı', error: e);
    }

    final hoursController = TextEditingController(
      text: timeOfDayDiffHours(startTime, endTime).toStringAsFixed(2),
    );
    final commentController = TextEditingController();

    if (!mounted) return;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void syncHoursFromStartEnd() {
              final h = timeOfDayDiffHours(startTime, endTime);
              hoursController.text = h.toStringAsFixed(2);
            }

            void syncEndFromHours() {
              final hoursText = hoursController.text.trim().replaceAll(',', '.');
              final h = double.tryParse(hoursText);
              if (h != null && h > 0) {
                endTime = addHoursToTimeOfDay(startTime, h);
              }
            }

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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.work_rounded, size: 20, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Builder(
                              builder: (context) {
                                final rawSubject = workPackage.subject.trim();
                                final title = rawSubject.isNotEmpty ? rawSubject : '#${workPackage.id}';
                                return Tooltip(
                                  message: title,
                                  child: GestureDetector(
                                    onLongPress: () {
                                      lightImpact();
                                      showAppSnackBar(context, title, duration: const Duration(seconds: 3));
                                    },
                                    child: Text(
                                      title,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tarih ve süre',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
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
                            final c = client;
                            if (c != null) {
                              final suggested = await _suggestedStartForDate(c, d);
                              final duration = timeOfDayDiffHours(startTime, endTime);
                              if (ctx.mounted) {
                                setModalState(() {
                                  pickedDate = d;
                                  startTime = suggested;
                                  endTime = addHoursToTimeOfDay(suggested, duration);
                                  syncHoursFromStartEnd();
                                });
                              }
                            } else {
                              setModalState(() => pickedDate = d);
                            }
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Tarih',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: Icon(Icons.calendar_today_rounded),
                          ),
                          child: Text(DateFormatters.formatDate(pickedDate)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: workStartTimeOfDay,
                          );
                          if (t != null) {
                            await TimeTrackingPrefs.setWorkStartTimeOfDay(t);
                            setModalState(() => workStartTimeOfDay = t);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(Icons.access_time_rounded, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              const SizedBox(width: 8),
                              Text(
                                'Mesai başlangıcı: ${formatTimeOfDay(workStartTimeOfDay)}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final t = await showTimePicker(
                                  context: context,
                                  initialTime: startTime,
                                );
                                if (t != null) {
                                  setModalState(() {
                                    startTime = t;
                                    syncEndFromHours();
                                    syncHoursFromStartEnd();
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Başlangıç',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  prefixIcon: Icon(Icons.play_arrow_rounded),
                                ),
                                child: Text(formatTimeOfDay(startTime)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final t = await showTimePicker(
                                  context: context,
                                  initialTime: endTime,
                                );
                                if (t != null) {
                                  setModalState(() {
                                    endTime = t;
                                    syncHoursFromStartEnd();
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Bitiş',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  prefixIcon: Icon(Icons.stop_rounded),
                                ),
                                child: Text(formatTimeOfDay(endTime)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: hoursController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Süre (saat)',
                          hintText: '1.0',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: Icon(Icons.schedule_rounded),
                        ),
                        onChanged: (_) {
                          setModalState(() {
                            syncEndFromHours();
                          });
                        },
                      ),
                      if (activities.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Aktivite',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: selectedActivityId,
                          decoration: InputDecoration(
                            labelText: 'Kategori (Aktivite)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: Icon(Icons.category_rounded),
                          ),
                          items: activities
                              .map((a) => DropdownMenuItem(
                                    value: a.id,
                                    child: Text(a.name),
                                  ))
                              .toList(),
                          onChanged: (v) => setModalState(() => selectedActivityId = v),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        'Yorum',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: commentController,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Yorum (isteğe bağlı)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.comment_outlined),
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
                          Semantics(
                            label: 'Zaman kaydını kaydet',
                            button: true,
                            child: FilledButton.icon(
                              onPressed: () async {
                                final hoursText = hoursController.text
                                    .trim()
                                    .replaceAll(',', '.');
                                final h = double.tryParse(hoursText);
                                if (h == null || h <= 0) {
                                  showErrorSnackBar(
                                    context,
                                    'Geçerli bir süre girin (örn. 0.5, 1, 1.5)',
                                  );
                                  return;
                                }
                                try {
                                  final c = client;
                                  if (c == null) return;
                                  await c.createTimeEntry(
                                    workPackageId: workPackage.id,
                                    hours: h,
                                    spentOn: pickedDate,
                                    comment: commentController.text.trim().isEmpty
                                        ? null
                                        : commentController.text.trim(),
                                    activityId: selectedActivityId,
                                  );
                                  if (context.mounted) {
                                    Navigator.of(context).pop(true);
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    showErrorSnackBar(context, e, duration: const Duration(seconds: 5));
                                  }
                                }
                              },
                              icon: const Icon(Icons.check_rounded),
                              label: const Text('Kaydet'),
                            ),
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
    try {
      if (saved == true && mounted) await _load();
    } finally {
      hoursController.dispose();
      commentController.dispose();
    }
  }

  /// Zaman kaydı düzenleme formu (detay sheet'ten "Düzenle" ile açılır).
  Future<void> _showEditTimeEntryForm(TimeEntry entry) async {
    final c = client;
    if (c == null) return;
    List<TimeEntryActivity> activities = [];
    try {
      activities = await c.getTimeEntryActivities();
    } catch (e) {
      if (kDebugMode) AppLogger.logError('Zaman girişi aktiviteleri yüklenirken hata', error: e);
    }
    final defaultActivities = activities.where((a) => a.isDefault).toList();
    String? selectedActivityId = entry.activityId ??
        (activities.isEmpty ? null : (defaultActivities.isNotEmpty ? defaultActivities.first.id : activities.first.id));

    DateTime pickedDate = entry.spentOn;
    final workStart = await TimeTrackingPrefs.getWorkStartTimeOfDay();
    TimeOfDay startTime = addHoursToTimeOfDay(workStart, 0);
    TimeOfDay endTime = addHoursToTimeOfDay(startTime, entry.hours);

    final hoursController = TextEditingController(text: entry.hours.toStringAsFixed(2));
    final commentController = TextEditingController(text: entry.comment ?? '');

    if (!mounted) return;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void syncHoursFromStartEnd() {
              final h = timeOfDayDiffHours(startTime, endTime);
              hoursController.text = h.toStringAsFixed(2);
            }
            void syncEndFromHours() {
              final hoursText = hoursController.text.trim().replaceAll(',', '.');
              final h = double.tryParse(hoursText);
              if (h != null && h > 0) endTime = addHoursToTimeOfDay(startTime, h);
            }
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Zaman kaydını düzenle',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tarih ve süre',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: pickedDate,
                            firstDate: DateTime(pickedDate.year - 1),
                            lastDate: DateTime(pickedDate.year + 1),
                          );
                          if (d != null) setModalState(() => pickedDate = d);
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Tarih',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: Icon(Icons.calendar_today_rounded),
                          ),
                          child: Text(DateFormatters.formatDate(pickedDate)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final t = await showTimePicker(context: context, initialTime: startTime);
                                if (t != null) {
                                  setModalState(() {
                                    startTime = t;
                                    syncEndFromHours();
                                    syncHoursFromStartEnd();
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(labelText: 'Başlangıç', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                                child: Text(formatTimeOfDay(startTime)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final t = await showTimePicker(context: context, initialTime: endTime);
                                if (t != null) {
                                  setModalState(() {
                                    endTime = t;
                                    syncHoursFromStartEnd();
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(labelText: 'Bitiş', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                                child: Text(formatTimeOfDay(endTime)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: hoursController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Süre (saat)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onChanged: (_) => setModalState(syncEndFromHours),
                      ),
                      if (activities.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Aktivite',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: selectedActivityId,
                          decoration: InputDecoration(
                            labelText: 'Kategori (Aktivite)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: activities
                              .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name)))
                              .toList(),
                          onChanged: (v) => setModalState(() => selectedActivityId = v),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        'Yorum',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: commentController,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Yorum (isteğe bağlı)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          alignLabelWithHint: true,
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
                          Semantics(
                            label: 'Zaman kaydı değişikliklerini kaydet',
                            button: true,
                            child: FilledButton.icon(
                              onPressed: () async {
                                final hoursText = hoursController.text.trim().replaceAll(',', '.');
                                final h = double.tryParse(hoursText);
                                if (h == null || h <= 0) {
                                  showErrorSnackBar(context, 'Geçerli bir süre girin.');
                                  return;
                                }
                                try {
                                  final c = client;
                                  if (c == null) return;
                                  await c.updateTimeEntry(
                                    entry.id,
                                    hours: h,
                                    spentOn: pickedDate,
                                    comment: commentController.text.trim().isEmpty ? null : commentController.text.trim(),
                                    activityId: selectedActivityId,
                                  );
                                  if (context.mounted) Navigator.of(context).pop(true);
                                } catch (e) {
                                  if (context.mounted) {
                                    showErrorSnackBar(context, e, duration: const Duration(seconds: 5));
                                  }
                                }
                              },
                              icon: const Icon(Icons.check_rounded),
                              label: const Text('Kaydet'),
                            ),
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
    try {
      if (saved == true && mounted) await _load();
    } finally {
      hoursController.dispose();
      commentController.dispose();
    }
  }

  @override
  void initState() {
    super.initState();
    loading = true;
    _loadPrefs();
    _load();
    if (widget.initialWorkPackageForTime != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.initialWorkPackageForTime != null) {
          _showTimeEntryForm(widget.initialWorkPackageForTime!);
        }
      });
    }
  }

  Future<void> _loadPrefs() async {
    final columns = await TimeTrackingPrefs.getColumns();
    final groupBy = await TimeTrackingPrefs.getGroupBy();
    final sortOrder = await TimeTrackingPrefs.getSortOrder();
    final sortBy = await TimeTrackingPrefs.getSortBy();
    final showTeam = await TimeTrackingPrefs.getShowTeam();
    if (!mounted) return;
    setState(() {
      _columns = columns;
      _groupBy = groupBy;
      _sortOrder = sortOrder;
      _sortBy = sortBy;
      _showTeam = showTeam;
    });
    if (showTeam) _loadProjectMembers();
  }

  Future<void> _loadProjectMembers() async {
    final auth = context.read<AuthState>();
    final c = client;
    final projectId = auth.activeProject?.id;
    if (c == null || projectId == null) return;
    try {
      final members = await c.getProjectMembers(projectId);
      final me = auth.client;
      String? myId;
      if (me != null) {
        try {
          final data = await me.getMe();
          myId = data['id']?.toString();
        } catch (e) {
          if (kDebugMode) AppLogger.logError('getMe çağrısı başarısız', error: e);
        }
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
      _probeCanViewTeamTime(c, myId, list);
    } catch (e) {
      if (kDebugMode) AppLogger.logError('Proje üyeleri yüklenirken hata', error: e);
      if (mounted) setState(() => _projectMembers = []);
    }
  }

  /// Başkasının zaman kayıtlarını görme yetkisi var mı (yönetici/izin) — API ile dener.
  Future<void> _probeCanViewTeamTime(OpenProjectClient client, String? myId, List<Map<String, String>> members) async {
    final others = members.where((m) => m['id'] != myId).map((m) => m['id']).whereType<String>().toList();
    final otherUserId = others.isNotEmpty ? others.first : null;
    if (otherUserId == null || otherUserId.isEmpty) {
      if (!mounted) return;
      setState(() => _canViewTeamTime = false);
      return;
    }
    try {
      final start = _today.subtract(const Duration(days: 7));
      final end = _today.add(const Duration(days: 1));
      await client.getMyTimeEntries(from: start, to: end, userId: otherUserId);
      if (!mounted) return;
      setState(() => _canViewTeamTime = true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _canViewTeamTime = false;
        if (_showTeam) {
          _showTeam = false;
          TimeTrackingPrefs.setShowTeam(false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthState>();
    if (auth.activeProject != null && _canViewTeamTime == null && _projectMembers.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _canViewTeamTime == null) _loadProjectMembers();
      });
    }

    final isPro = context.watch<ProState>().isPro;
    final themeForBadge = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zaman takibi'),
        actions: [
          isPro
              ? IconButton(
                  onPressed: () => _openColumnSelector(context),
                  icon: const Icon(Icons.view_column),
                  tooltip: 'Kolonlar',
                )
              : Badge(
                  label: Icon(Icons.star_rounded, size: 10, color: themeForBadge.colorScheme.onPrimary),
                  backgroundColor: themeForBadge.colorScheme.primary,
                  smallSize: 16,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.proUpgrade),
                    icon: const Icon(Icons.view_column),
                    tooltip: 'Kolonlar (Pro\'da)',
                  ),
                ),
          IconButton(
            onPressed: () async {
              lightImpact();
              await _load();
            },
            tooltip: 'Zaman listesini yenile',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ProGate(
        showTeaser: true,
        message: 'Zaman takibi gelişmiş özellikleri Pro sürümünde. Kullanmak için Pro\'yu satın alın.',
        child: AsyncContent(
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
                        _TimeTrackingSummaryRow(
                          totalToday: _totalToday(),
                          totalThisWeek: _totalThisWeek(),
                          totalThisMonth: _totalThisMonth(),
                        ),
                        const SizedBox(height: 16),
                        _TimeTrackingViewModeBar(
                          viewMode: _viewMode,
                          onTable: () {
                            mediumImpact();
                            setState(() => _viewMode = _TimeViewMode.table);
                          },
                          onGantt: () {
                            mediumImpact();
                            setState(() => _viewMode = _TimeViewMode.gantt);
                          },
                        ),
                        const SizedBox(height: 16),
                        if (_viewMode == _TimeViewMode.table) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Tooltip(
                              message: 'Gruplama: ${_groupBy.label}',
                              child: PopupMenuButton<TimeTrackingGroupBy>(
                                icon: Icon(Icons.view_agenda_rounded, color: theme.colorScheme.primary),
                                tooltip: '',
                                padding: EdgeInsets.zero,
                                onSelected: (v) {
                                  lightImpact();
                                  setState(() => _groupBy = v);
                                  TimeTrackingPrefs.setGroupBy(v);
                                },
                                itemBuilder: (ctx) => TimeTrackingGroupBy.values
                                    .map((g) => PopupMenuItem(
                                          value: g,
                                          child: Row(
                                            children: [
                                              if (_groupBy == g) Icon(Icons.check_rounded, size: 20, color: theme.colorScheme.primary),
                                              if (_groupBy == g) const SizedBox(width: 8),
                                              Text(g.label),
                                            ],
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Tooltip(
                              message: 'Sıralama: ${_sortOrder.label}',
                              child: PopupMenuButton<TimeTrackingSortOrder>(
                                icon: Icon(
                                  _sortOrder == TimeTrackingSortOrder.newestFirst ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                  color: theme.colorScheme.primary,
                                ),
                                tooltip: '',
                                padding: EdgeInsets.zero,
                                onSelected: (v) {
                                  lightImpact();
                                  setState(() {
                                    _sortOrder = v;
                                    TimeTrackingPrefs.sortTimeEntries(_entries, v, _sortBy);
                                  });
                                  TimeTrackingPrefs.setSortOrder(v);
                                },
                                itemBuilder: (ctx) => TimeTrackingSortOrder.values
                                    .map((o) => PopupMenuItem(
                                          value: o,
                                          child: Row(
                                            children: [
                                              if (_sortOrder == o) Icon(Icons.check_rounded, size: 20, color: theme.colorScheme.primary),
                                              if (_sortOrder == o) const SizedBox(width: 8),
                                              Text(o.label),
                                            ],
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Tooltip(
                              message: 'Kriter: ${_sortBy.label}',
                              child: PopupMenuButton<TimeTrackingSortBy>(
                                icon: Icon(
                                  _sortBy == TimeTrackingSortBy.spentOn ? Icons.calendar_today_rounded : Icons.schedule_rounded,
                                  color: theme.colorScheme.primary,
                                ),
                                tooltip: '',
                                padding: EdgeInsets.zero,
                                onSelected: (v) {
                                  lightImpact();
                                  setState(() {
                                    _sortBy = v;
                                    TimeTrackingPrefs.sortTimeEntries(_entries, _sortOrder, v);
                                  });
                                  TimeTrackingPrefs.setSortBy(v);
                                },
                                itemBuilder: (ctx) => TimeTrackingSortBy.values
                                    .map((s) => PopupMenuItem(
                                          value: s,
                                          child: Row(
                                            children: [
                                              if (_sortBy == s) Icon(Icons.check_rounded, size: 20, color: theme.colorScheme.primary),
                                              if (_sortBy == s) const SizedBox(width: 8),
                                              Text(s.label),
                                            ],
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),
                            if (auth.activeProject != null) ...[
                              const SizedBox(width: 4),
                              Tooltip(
                                message: _canViewTeamTime == false
                                    ? 'Ekip zamanları (yetki yok)'
                                    : _showTeam
                                        ? 'Ekip kullanıcısı'
                                        : 'Ekip zamanları',
                                child: _canViewTeamTime == true
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              _showTeam ? Icons.group_rounded : Icons.group_outlined,
                                              color: _showTeam ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                                            ),
                                            tooltip: _showTeam ? 'Takım görünümünü kapat' : 'Takım görünümünü aç',
                                            onPressed: () async {
                                              lightImpact();
                                              setState(() => _showTeam = !_showTeam);
                                              TimeTrackingPrefs.setShowTeam(_showTeam);
                                              if (_showTeam) {
                                                await _loadProjectMembers();
                                                if (mounted) _load();
                                              } else {
                                                _load();
                                              }
                                            },
                                          ),
                                          if (_showTeam && _projectMembers.isNotEmpty)
                                            TimeTrackingTeamSelector(
                                              projectMembers: _projectMembers,
                                              selectedUserId: _selectedUserId,
                                              onSelected: (v) {
                                                setState(() => _selectedUserId = v);
                                                _load();
                                              },
                                            ),
                                        ],
                                      )
                                    : IconButton(
                                        tooltip: 'Takım görünümü (Pro)',
                                        icon: Icon(Icons.group_outlined, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                                        onPressed: null,
                                      ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),
                        TimeTrackingDataTable(
                          entries: _entries,
                          columnIds: _columns,
                          groupBy: _groupBy,
                          instanceApiBaseUrl: auth.instanceApiBaseUrl,
                          authHeadersForAvatars: auth.authHeadersForInstanceImages,
                          onEntryTap: (e) => showTimeEntryDetailSheet(
                            context: context,
                            entry: e,
                            onOpenWorkPackage: _openWorkPackageFromTimeEntry,
                            onDeleted: _load,
                            onEditRequested: _showEditTimeEntryForm,
                          ),
                        ),
                        ] else ...[
                        SizedBox(
                          height: 450,
                          child: TimeEntriesGantt(
                            entries: _entries,
                            onRefresh: _load,
                          ),
                        ),
                        ],
                      ],
                    ),
                  ),
                ),
        ),
      ),
      floatingActionButton: isPro
          ? FloatingActionButton(
              heroTag: 'time_tracking_add',
              onPressed: _openAddTimeEntry,
              tooltip: 'Zaman kaydı ekle',
              child: const Icon(Icons.add_rounded),
            )
          : Badge(
              label: Icon(Icons.star_rounded, size: 12, color: themeForBadge.colorScheme.onPrimary),
              backgroundColor: themeForBadge.colorScheme.primary,
              smallSize: 18,
              child: FloatingActionButton(
                heroTag: 'time_tracking_add',
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.proUpgrade),
                tooltip: 'Zaman kaydı ekle (Pro\'da)',
                child: const Icon(Icons.add_rounded),
              ),
            ),
    );
  }

  void _openWorkPackageFromTimeEntry(WorkPackage wp) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkPackageDetailScreen(workPackage: wp),
      ),
    ).then((_) {
      if (mounted) _load();
    });
  }

  void _openColumnSelector(BuildContext context) {
    lightImpact();
    final theme = Theme.of(context);
    var selected = List<String>.from(_columns);
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
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

/// Zaman takibi özet satırı: Bugün / Bu hafta / Bu ay toplamları.
class _TimeTrackingSummaryRow extends StatelessWidget {
  final double totalToday;
  final double totalThisWeek;
  final double totalThisMonth;

  const _TimeTrackingSummaryRow({
    required this.totalToday,
    required this.totalThisWeek,
    required this.totalThisMonth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Bugün',
            hours: totalToday,
            color: theme.colorScheme.primary,
            icon: Icons.today,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            title: 'Bu hafta',
            hours: totalThisWeek,
            color: theme.colorScheme.secondary,
            icon: Icons.date_range,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            title: 'Bu ay',
            hours: totalThisMonth,
            color: theme.colorScheme.tertiary,
            icon: Icons.calendar_month,
          ),
        ),
      ],
    );
  }
}

/// Zaman takibi görünüm modu: Tablo / Gantt.
class _TimeTrackingViewModeBar extends StatelessWidget {
  final _TimeViewMode viewMode;
  final VoidCallback onTable;
  final VoidCallback onGantt;

  const _TimeTrackingViewModeBar({
    required this.viewMode,
    required this.onTable,
    required this.onGantt,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FilterIconButton(
          icon: Icons.view_list_rounded,
          selectedIcon: Icons.view_list_rounded,
          tooltip: 'Tablo',
          selected: viewMode == _TimeViewMode.table,
          onPressed: onTable,
        ),
        const SizedBox(width: 8),
        FilterIconButton(
          icon: Icons.date_range_rounded,
          selectedIcon: Icons.date_range_rounded,
          tooltip: 'Gantt',
          selected: viewMode == _TimeViewMode.gantt,
          onPressed: onGantt,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double hours;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.hours,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      color: color.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${hours.toStringAsFixed(1)} s',
              style: theme.textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

