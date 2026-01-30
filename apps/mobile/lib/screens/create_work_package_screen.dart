import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/openproject_client.dart';
import '../utils/app_logger.dart';
import '../mixins/client_context_mixin.dart';
import '../models/project.dart';
import '../models/version.dart';
import '../models/work_package.dart';
import '../state/auth_state.dart';
import '../utils/error_messages.dart';
import '../utils/haptic.dart';
import '../constants/app_strings.dart';
import '../utils/snackbar_helpers.dart';
import '../widgets/async_content.dart';
import '../widgets/letter_avatar.dart';
import '../widgets/projectflow_logo_button.dart';
import '../widgets/small_loading_indicator.dart';
import 'work_package_detail_screen.dart';

/// Web/API’den gelen hex rengi (örn. #3997AD) Color’a çevirir.
Color? _colorFromHex(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  String h = hex.startsWith('#') ? hex.substring(1) : hex;
  if (h.length == 6) h = 'FF$h';
  if (h.length != 8) return null;
  final n = int.tryParse(h, radix: 16);
  return n != null ? Color(n) : null;
}

/// Arka plan rengine göre okunabilir metin rengi (beyaz veya siyah).
Color _contrastOn(Color bg) {
  final luminance = bg.computeLuminance();
  return luminance > 0.4 ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
}

/// Yeni iş paketi oluşturma ekranı. Web formundaki alanlar: proje, tip, başlık, açıklama,
/// atanan, öncelik, durum, üst iş, versiyon, başlangıç/bitiş tarihi. Sesle giriş aktif.
class CreateWorkPackageScreen extends StatefulWidget {
  const CreateWorkPackageScreen({super.key});

  @override
  State<CreateWorkPackageScreen> createState() => _CreateWorkPackageScreenState();
}

class _CreateWorkPackageScreenState extends State<CreateWorkPackageScreen> with ClientContextMixin<CreateWorkPackageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _parentIdController = TextEditingController();
  final _subjectFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();

  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<Project> _projects = const [];
  List<Map<String, String>> _types = const [];
  List<Map<String, String>> _statuses = const [];
  List<Map<String, String>> _priorities = const [];
  List<Map<String, String>> _members = const [];
  List<Version> _versions = const [];
  Project? _selectedProject;
  String? _selectedTypeId;
  String? _selectedStatusId;
  String? _selectedPriorityId;
  String? _selectedAssigneeId;
  String? _selectedVersionId;
  DateTime? _startDate;
  DateTime? _dueDate;
  WorkPackage? _selectedParent;


  /// Durum: API’deki color (web ayarları) varsa onu kullanır, yoksa isim bazlı fallback.
  (Color bg, Color fg, IconData icon) _statusVisualsFromMap(BuildContext context, Map<String, String> s) {
    final name = s['name'] ?? s['id'] ?? '';
    final apiColor = _colorFromHex(s['color']);
    if (apiColor != null) {
      return (apiColor, _contrastOn(apiColor), _statusIconByName(name));
    }
    return _statusVisuals(context, name);
  }

  static IconData _statusIconByName(String status) {
    final s = status.toLowerCase();
    if (s.contains('yeni') || s.contains('new')) return Icons.fiber_new_rounded;
    if (s.contains('devam') || s.contains('progress') || s.contains('in progress')) return Icons.play_arrow_rounded;
    if (s.contains('bekle') || s.contains('on hold') || s.contains('pending')) return Icons.pause_circle_filled_rounded;
    if (s.contains('tamam') || s.contains('closed') || s.contains('done') || s.contains('çözüldü')) return Icons.check_circle_rounded;
    if (s.contains('iptal') || s.contains('cancel')) return Icons.cancel_rounded;
    return Icons.adjust_rounded;
  }

  /// Durum için renk ve ikon (API rengi yoksa fallback).
  (Color bg, Color fg, IconData icon) _statusVisuals(BuildContext context, String status) {
    final theme = Theme.of(context);
    final s = status.toLowerCase();
    if (s.contains('yeni') || s.contains('new')) {
      return (theme.colorScheme.primaryContainer, theme.colorScheme.onPrimaryContainer, Icons.fiber_new_rounded);
    }
    if (s.contains('devam') || s.contains('progress') || s.contains('in progress')) {
      return (theme.colorScheme.tertiaryContainer, theme.colorScheme.onTertiaryContainer, Icons.play_arrow_rounded);
    }
    if (s.contains('bekle') || s.contains('on hold') || s.contains('pending')) {
      return (theme.colorScheme.surfaceContainerHighest, theme.colorScheme.onSurfaceVariant, Icons.pause_circle_filled_rounded);
    }
    if (s.contains('tamam') || s.contains('closed') || s.contains('done') || s.contains('çözüldü')) {
      return (theme.colorScheme.secondaryContainer, theme.colorScheme.onSecondaryContainer, Icons.check_circle_rounded);
    }
    if (s.contains('iptal') || s.contains('cancel')) {
      return (theme.colorScheme.errorContainer, theme.colorScheme.onErrorContainer, Icons.cancel_rounded);
    }
    return (theme.colorScheme.primaryContainer, theme.colorScheme.onPrimaryContainer, _statusIconByName(status));
  }

  /// İş tipi: API’deki color (web ayarları) varsa onu kullanır, yoksa isim bazlı fallback.
  (Color bg, Color fg, IconData icon) _typeVisualsFromMap(BuildContext context, Map<String, String> t) {
    final name = t['name'] ?? t['id'] ?? '';
    final apiColor = _colorFromHex(t['color']);
    if (apiColor != null) {
      return (apiColor, _contrastOn(apiColor), _typeIconByName(name));
    }
    return _typeVisuals(context, name);
  }

  static IconData _typeIconByName(String type) {
    final t = type.toLowerCase();
    if (t.contains('bug') || t.contains('hata')) return Icons.bug_report_rounded;
    if (t.contains('task') || t.contains('görev')) return Icons.checklist_rounded;
    if (t.contains('feature') || t.contains('özellik')) return Icons.auto_awesome_rounded;
    if (t.contains('milestone') || t.contains('kilometre')) return Icons.flag_rounded;
    return Icons.label_rounded;
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

  /// İş tipi için renk ve ikon (API rengi yoksa fallback).
  (Color bg, Color fg, IconData icon) _typeVisuals(BuildContext context, String type) {
    final theme = Theme.of(context);
    return (theme.colorScheme.surfaceContainerHighest, theme.colorScheme.onSurfaceVariant, _typeIconByName(type));
  }

  /// Atanan için avatar URL (instance API base + users/id/avatar).
  String? _avatarUrlForUser(AuthState auth, String userId) {
    final base = auth.instanceApiBaseUrl;
    if (base == null || base.isEmpty) return null;
    return '$base/users/$userId/avatar';
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
      _types = const [];
      _statuses = const [];
      _priorities = const [];
      _members = const [];
      _versions = const [];
      _selectedTypeId = null;
      _selectedStatusId = null;
      _selectedPriorityId = null;
      _selectedAssigneeId = null;
      _selectedVersionId = null;
    });
    try {
      final c = client;
      if (c == null) throw Exception('Oturum bulunamadı.');
      final auth = context.read<AuthState>();
      _projects = await c.getProjects();
      final statuses = await c.getStatuses();
      final priorities = await c.getPriorities();
      Project? preSelect;
      if (_projects.isNotEmpty && auth.activeProject != null) {
        final match = _projects.where((p) => p.id == auth.activeProject!.id).toList();
        if (match.isNotEmpty) preSelect = match.first;
      }
      if (preSelect != null) {
        _selectedProject = preSelect;
        await _loadProjectDependent(preSelect.id);
      }
      if (mounted) {
        setState(() {
          _statuses = statuses;
          _priorities = priorities;
          if (_types.isNotEmpty && _selectedTypeId == null) _selectedTypeId = _types.first['id'];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ErrorMessages.userFriendly(e);
          _projects = const [];
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadProjectDependent(String projectId) async {
    final c = client;
    if (c == null) return;
    try {
      final types = await c.getProjectTypes(projectId);
      final members = await c.getProjectMembers(projectId);
      final versions = await c.getProjectVersions(projectId);
      if (mounted) {
        setState(() {
          _types = types;
          _members = members;
          _versions = versions;
          if (_types.isNotEmpty) _selectedTypeId = _types.first['id'];
          _selectedAssigneeId = null;
          _selectedVersionId = null;
        });
      }
    } catch (e) {
      if (kDebugMode) AppLogger.logError('Proje tipleri/üyeler/versiyonlar yüklenemedi', error: e);
      if (mounted) {
        setState(() {
          _types = const [];
          _members = const [];
          _versions = const [];
        });
      }
    }
  }

  void _showVoiceHint() {
    if (mounted) {
      showAppSnackBar(context, 'Klavyede mikrofon ile sesli yazabilirsiniz.');
    }
  }

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final initial = isStart ? (_startDate ?? DateTime.now()) : (_dueDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _dueDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true || _saving) return;
    final project = _selectedProject;
    final typeId = _selectedTypeId;
    if (project == null || typeId == null || typeId.isEmpty) {
      setState(() => _error = 'Proje ve iş tipi seçin.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final c = client;
      if (c == null) throw Exception('Oturum bulunamadı.');
      final parentId = _selectedParent?.id ?? _parentIdController.text.trim();
      final wp = await c.createWorkPackage(
        projectId: project.id,
        typeId: typeId,
        subject: _subjectController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        assigneeId: _selectedAssigneeId?.isEmpty == true ? null : _selectedAssigneeId,
        priorityId: _selectedPriorityId?.isEmpty == true ? null : _selectedPriorityId,
        statusId: _selectedStatusId?.isEmpty == true ? null : _selectedStatusId,
        parentId: parentId.isEmpty ? null : parentId,
        versionId: _selectedVersionId?.isEmpty == true ? null : _selectedVersionId,
        startDate: _startDate,
        dueDate: _dueDate,
      );
      if (mounted) {
        mediumImpact();
        setState(() => _saving = false);
        showAppSnackBar(context, 'İş paketi oluşturuldu.');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => WorkPackageDetailScreen(workPackage: wp),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = ErrorMessages.userFriendly(e);
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    _parentIdController.dispose();
    _subjectFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni iş paketi'),
        actions: const [ProjectFlowLogoButton()],
      ),
      body: AsyncContent(
        loading: _loading,
        error: _error != null && _projects.isEmpty ? _error : null,
        onRetry: _loadInitial,
        child: Builder(
                  builder: (context) {
                    final theme = Theme.of(context);
                    final auth = context.watch<AuthState>();
                    return CustomScrollView(
                      slivers: [
                        SliverAppBar(
                          title: const Text('Yeni iş paketi'),
                          actions: const [ProjectFlowLogoButton()],
                          floating: true,
                          snap: true,
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.all(24),
                          sliver: SliverToBoxAdapter(
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  DropdownButtonFormField<Project>(
                              initialValue: _selectedProject,
                              decoration: InputDecoration(
                                labelText: 'Proje',
                                prefixIcon: Icon(Icons.folder_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: _projects
                                  .map((p) => DropdownMenuItem(
                                        value: p,
                                        child: LayoutBuilder(
                                          builder: (context, constraints) {
                                            final w = constraints.maxWidth.isFinite && constraints.maxWidth > 0
                                                ? constraints.maxWidth
                                                : 250.0;
                                            return SizedBox(
                                              width: w,
                                              child: Row(
                                                children: [
                                                  Icon(Icons.folder_rounded, size: 20, color: theme.colorScheme.primary),
                                                  const SizedBox(width: 12),
                                                  Expanded(child: Text(p.name, overflow: TextOverflow.ellipsis)),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (p) {
                                setState(() {
                                  _selectedProject = p;
                                  if (p != null) _loadProjectDependent(p.id);
                                });
                              },
                              validator: (v) => v == null ? 'Proje seçin.' : null,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedTypeId,
                              decoration: InputDecoration(
                                labelText: 'İş tipi',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: _types
                                  .map((t) {
                                    final name = t['name'] ?? t['id'] ?? '';
                                    final (bg, fg, icon) = _typeVisualsFromMap(context, t);
                                    return DropdownMenuItem<String>(
                                      value: t['id'],
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: bg,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(icon, size: 18, color: fg),
                                                const SizedBox(width: 6),
                                                Text(name, style: theme.textTheme.bodySmall?.copyWith(color: fg)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  })
                                  .toList(),
                              onChanged: (v) => setState(() => _selectedTypeId = v),
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'İş tipi seçin.' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _subjectController,
                              focusNode: _subjectFocusNode,
                              decoration: InputDecoration(
                                labelText: 'Başlık',
                                hintText: 'İş paketi başlığı',
                                prefixIcon: const Icon(Icons.title_rounded),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.mic_outlined),
                                  onPressed: () {
                                    _subjectFocusNode.requestFocus();
                                    _showVoiceHint();
                                  },
                                  tooltip: 'Sesle yazmak için alana odaklan',
                                ),
                              ),
                              autofillHints: const [AutofillHints.name],
                              textCapitalization: TextCapitalization.sentences,
                              maxLength: 255,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Başlık zorunlu.';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _descriptionController,
                              focusNode: _descriptionFocusNode,
                              decoration: InputDecoration(
                                labelText: 'Açıklama (isteğe bağlı)',
                                prefixIcon: const Icon(Icons.notes_rounded),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                alignLabelWithHint: true,
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.mic_outlined),
                                  onPressed: () {
                                    _descriptionFocusNode.requestFocus();
                                    _showVoiceHint();
                                  },
                                  tooltip: 'Sesle yazmak için alana odaklan',
                                ),
                              ),
                              maxLines: 4,
                              textCapitalization: TextCapitalization.sentences,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedAssigneeId == null || _selectedAssigneeId!.isEmpty
                                  ? null
                                  : _selectedAssigneeId,
                              decoration: InputDecoration(
                                labelText: 'Atanan',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: [
                                DropdownMenuItem<String>(
                                  value: null,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      LetterAvatar(
                                        displayName: 'Atanmamış',
                                        imageUrl: null,
                                        size: 28,
                                      ),
                                      const SizedBox(width: 12),
                                      const Text('— Atanmamış'),
                                    ],
                                  ),
                                ),
                                ..._members.map((m) {
                                  final id = m['id']!;
                                  final name = m['name'] ?? id;
                                  final avatarUrl = _avatarUrlForUser(auth, id);
                                  final headers = auth.authHeadersForInstanceImages;
                                  return DropdownMenuItem<String>(
                                    value: id,
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        final w = constraints.maxWidth.isFinite && constraints.maxWidth > 0
                                            ? constraints.maxWidth
                                            : 250.0;
                                        return SizedBox(
                                          width: w,
                                          child: Row(
                                            children: [
                                              LetterAvatar(
                                                displayName: name,
                                                imageUrl: avatarUrl,
                                                imageHeaders: headers,
                                                size: 28,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(child: Text(name, overflow: TextOverflow.ellipsis)),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                }),
                              ],
                              onChanged: (v) => setState(() => _selectedAssigneeId = v),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedPriorityId,
                              decoration: InputDecoration(
                                labelText: 'Öncelik',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: _priorities
                                  .map((p) {
                                    final name = p['name'] ?? p['id'] ?? '';
                                    final (bg, fg, icon) = _priorityVisuals(context, name);
                                    return DropdownMenuItem<String>(
                                      value: p['id'],
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: bg,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(icon, size: 18, color: fg),
                                                const SizedBox(width: 6),
                                                Text(name, style: theme.textTheme.bodySmall?.copyWith(color: fg)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  })
                                  .toList(),
                              onChanged: (v) => setState(() => _selectedPriorityId = v),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedStatusId,
                              decoration: InputDecoration(
                                labelText: 'Durum',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: _statuses
                                  .map((s) {
                                    final name = s['name'] ?? s['id'] ?? '';
                                    final (bg, fg, icon) = _statusVisualsFromMap(context, s);
                                    return DropdownMenuItem<String>(
                                      value: s['id'],
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: bg,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(icon, size: 18, color: fg),
                                                const SizedBox(width: 6),
                                                Text(name, style: theme.textTheme.bodySmall?.copyWith(color: fg)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  })
                                  .toList(),
                              onChanged: (v) => setState(() => _selectedStatusId = v),
                            ),
                            const SizedBox(height: 16),
                            _ParentWorkPackageSelector(
                              selectedParent: _selectedParent,
                              projectId: _selectedProject?.id,
                              client: client,
                              onSelect: (wp) {
                                setState(() {
                                  _selectedParent = wp;
                                  _parentIdController.text = wp.id;
                                });
                              },
                              onClear: () {
                                setState(() {
                                  _selectedParent = null;
                                  _parentIdController.clear();
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            if (_versions.isNotEmpty)
                              DropdownButtonFormField<String>(
                                initialValue: _selectedVersionId,
                                decoration: InputDecoration(
                                  labelText: 'Versiyon / Sprint',
                                  prefixIcon: Icon(Icons.flag_outlined),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                items: [
                                  DropdownMenuItem<String>(
                                    value: null,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.flag_outlined, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                        const SizedBox(width: 12),
                                        const Text('— Seçiniz'),
                                      ],
                                    ),
                                  ),
                                  ..._versions.map((v) => DropdownMenuItem<String>(
                                        value: v.id.toString(),
                                        child: LayoutBuilder(
                                          builder: (context, constraints) {
                                            final w = constraints.maxWidth.isFinite && constraints.maxWidth > 0
                                                ? constraints.maxWidth
                                                : 250.0;
                                            return SizedBox(
                                              width: w,
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    v.isOpen ? Icons.directions_run_rounded : Icons.flag_rounded,
                                                    size: 20,
                                                    color: v.isOpen ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      '${v.name}${v.isOpen ? ' (açık)' : ''}',
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      )),
                                ],
                                onChanged: (v) => setState(() => _selectedVersionId = v),
                              ),
                            if (_versions.isNotEmpty) const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _pickDate(context, true),
                                    icon: const Icon(Icons.calendar_today, size: 18),
                                    label: Text(
                                      _startDate != null
                                          ? '${_startDate!.day}.${_startDate!.month}.${_startDate!.year}'
                                          : 'Başlangıç',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _pickDate(context, false),
                                    icon: const Icon(Icons.event, size: 18),
                                    label: Text(
                                      _dueDate != null
                                          ? '${_dueDate!.day}.${_dueDate!.month}.${_dueDate!.year}'
                                          : 'Bitiş',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.errorContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _error!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: _saving ? null : _submit,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: _saving
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: SmallLoadingIndicator(),
                                    )
                                  : const Text('Oluştur'),
                            ),
                                  const SizedBox(height: 32),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
      ),
    );
  }
}

/// Üst iş seçimi: liste ile arama; tam liste yüklenmez, yazıldıkça aranır.
class _ParentWorkPackageSelector extends StatefulWidget {
  final WorkPackage? selectedParent;
  final String? projectId;
  final OpenProjectClient? client;
  final void Function(WorkPackage) onSelect;
  final VoidCallback onClear;

  const _ParentWorkPackageSelector({
    required this.selectedParent,
    required this.projectId,
    required this.client,
    required this.onSelect,
    required this.onClear,
  });

  @override
  State<_ParentWorkPackageSelector> createState() => _ParentWorkPackageSelectorState();
}

class _ParentWorkPackageSelectorState extends State<_ParentWorkPackageSelector> {
  void _openSearch() {
    if (widget.projectId == null || widget.client == null) {
      showErrorSnackBar(context, AppStrings.errorSelectProjectFirst);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _ParentSearchSheet(
        projectId: widget.projectId!,
        client: widget.client!,
        onSelect: (wp) {
          widget.onSelect(wp);
          Navigator.of(ctx).pop();
        },
        onClear: () {
          widget.onClear();
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final parent = widget.selectedParent;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Üst iş',
        hintText: 'Ara veya seçin…',
        prefixIcon: const Icon(Icons.account_tree_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: InkWell(
        onTap: _openSearch,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  parent != null ? '#${parent.id} — ${parent.subject}' : 'Üst iş seçin (arama ile)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: parent != null ? null : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (parent != null)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: widget.onClear,
                  tooltip: 'Üst işi kaldır',
                ),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParentSearchSheet extends StatefulWidget {
  final String projectId;
  final OpenProjectClient client;
  final void Function(WorkPackage) onSelect;
  final VoidCallback onClear;

  const _ParentSearchSheet({
    required this.projectId,
    required this.client,
    required this.onSelect,
    required this.onClear,
  });

  @override
  State<_ParentSearchSheet> createState() => _ParentSearchSheetState();
}

class _ParentSearchSheetState extends State<_ParentSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<WorkPackage> _results = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _doSearch(_searchController.text.trim());
    });
  }

  Future<void> _doSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _loading = false;
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await widget.client.searchWorkPackagesForParent(
        projectId: widget.projectId,
        query: query,
        pageSize: 20,
      );
      if (mounted) {
        setState(() {
          _results = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ErrorMessages.userFriendly(e);
          _results = [];
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'ID veya başlıkla ara...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                    ),
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: widget.onClear,
                  child: const Text('Temizle'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
            child: AsyncContent(
              loading: _loading,
              error: _error,
              onRetry: () => _doSearch(_searchController.text.trim()),
              child: _searchController.text.trim().isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Üst iş seçmek için ID veya başlık yazın.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    )
                  : _results.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Sonuç yok.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _results.length,
                          itemBuilder: (context, i) {
                            final wp = _results[i];
                            return ListTile(
                              leading: const Icon(Icons.account_tree_outlined),
                              title: Text('#${wp.id}'),
                              subtitle: Text(wp.subject, overflow: TextOverflow.ellipsis),
                              onTap: () => widget.onSelect(wp),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
